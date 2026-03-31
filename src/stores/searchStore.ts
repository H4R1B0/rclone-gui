import { create } from 'zustand';

export interface SearchResult extends RcloneFile {
  RemoteFs: string;
}

interface SearchState {
  isOpen: boolean;
  query: string;
  isSearching: boolean;
  hasSearched: boolean;
  results: SearchResult[];
  error: string | null;
  selectedClouds: string[]; // List of specific clouds to search. If empty, search all.
  searchId: string | null;  // Active search session ID

  setIsOpen: (isOpen: boolean) => void;
  setQuery: (query: string) => void;
  setSearching: (isSearching: boolean) => void;
  setHasSearched: (hasSearched: boolean) => void;
  setResults: (results: SearchResult[]) => void;
  appendResults: (results: SearchResult[]) => void;
  setError: (error: string | null) => void;
  setSelectedClouds: (clouds: string[]) => void;
  toggleCloud: (cloud: string) => void;
  setSearchId: (id: string | null) => void;
  reset: () => void;
}

export const useSearchStore = create<SearchState>((set) => ({
  isOpen: false,
  query: '',
  isSearching: false,
  hasSearched: false,
  results: [],
  error: null,
  selectedClouds: [],
  searchId: null,

  setIsOpen: (isOpen) => set({ isOpen }),
  setQuery: (query) => set({ query }),
  setSearching: (isSearching) => set({ isSearching }),
  setHasSearched: (hasSearched) => set({ hasSearched }),
  setResults: (results) => set({ results }),
  appendResults: (newResults) =>
    set((state) => ({ results: [...state.results, ...newResults] })),
  setError: (error) => set({ error }),
  setSelectedClouds: (selectedClouds) => set({ selectedClouds }),
  toggleCloud: (cloud) =>
    set((state) => ({
      selectedClouds: state.selectedClouds.includes(cloud)
        ? state.selectedClouds.filter((c) => c !== cloud)
        : [...state.selectedClouds, cloud],
    })),
  setSearchId: (searchId) => set({ searchId }),
  reset: () => set({ query: '', isSearching: false, hasSearched: false, results: [], error: null, searchId: null }),
}));
