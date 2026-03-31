import { useCallback, useEffect, useRef } from 'react';
import { useSearchStore, type SearchResult } from '../stores/searchStore';
import { usePanelStore } from '../stores/panelStore';

export function useSearch() {
  const { query, selectedClouds, setSearching, setHasSearched, setResults, appendResults, setError, setSearchId } = useSearchStore();
  const { remotes } = usePanelStore();
  const cleanupRef = useRef<(() => void) | null>(null);

  // Set up IPC event listeners for streaming results
  useEffect(() => {
    const unsubResults = window.rcloneAPI.onSearchResults((searchId, results) => {
      const currentId = useSearchStore.getState().searchId;
      if (searchId === currentId) {
        appendResults(results as SearchResult[]);
      }
    });

    const unsubDone = window.rcloneAPI.onSearchDone((searchId) => {
      const currentId = useSearchStore.getState().searchId;
      if (searchId === currentId) {
        setSearching(false);
        setSearchId(null);
      }
    });

    cleanupRef.current = () => {
      unsubResults();
      unsubDone();
    };

    return () => {
      unsubResults();
      unsubDone();
    };
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const performSearch = useCallback(async () => {
    if (!query.trim()) {
      setResults([]);
      return;
    }

    // Abort any previous search
    const prevId = useSearchStore.getState().searchId;
    if (prevId) {
      await window.rcloneAPI.searchAbort(prevId);
    }

    setSearching(true);
    setHasSearched(true);
    setError(null);
    setResults([]);

    try {
      const allCloudRemotes = remotes.filter((r) => r !== '/');
      const targets = selectedClouds.length > 0 ? selectedClouds : allCloudRemotes;

      if (targets.length === 0) {
        setSearching(false);
        return;
      }

      // Generate unique search ID
      const searchId = `search_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
      setSearchId(searchId);

      // Start streaming search (non-blocking, results come via IPC events)
      window.rcloneAPI.searchStream(searchId, targets, query).catch((err) => {
        setError(err instanceof Error ? err.message : 'Search failed');
        setSearching(false);
        setSearchId(null);
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Search failed');
      setSearching(false);
    }
  }, [query, selectedClouds, remotes, setSearching, setHasSearched, setResults, appendResults, setError, setSearchId]);

  const abortSearch = useCallback(async () => {
    const currentId = useSearchStore.getState().searchId;
    if (currentId) {
      await window.rcloneAPI.searchAbort(currentId);
      setSearching(false);
      setSearchId(null);
    }
  }, [setSearching, setSearchId]);

  return { performSearch, abortSearch };
}
