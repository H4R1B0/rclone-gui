import { useEffect, useState } from 'react';
import { X, Loader2 } from 'lucide-react';
import { useT } from '../../lib/i18n';
import { formatBytes, formatDate } from '../../lib/utils';

interface PropertiesModalProps {
  file: RcloneFile;
  remote: string;
  path: string;
  onClose: () => void;
}

export function PropertiesModal({ file, remote, path, onClose }: PropertiesModalProps) {
  const t = useT();
  const [hashes, setHashes] = useState<Record<string, string> | null>(null);
  const [hashLoading, setHashLoading] = useState(false);

  const fullPath = path ? `${path}/${file.Name}` : file.Name;

  useEffect(() => {
    if (file.IsDir) return;
    setHashLoading(true);
    window.rcloneAPI.hashFile(remote, fullPath)
      .then((result) => setHashes(result))
      .catch(() => setHashes({}))
      .finally(() => setHashLoading(false));
  }, [remote, fullPath, file.IsDir]);

  const Row = ({ label, value }: { label: string; value: string }) => (
    <div className="grid grid-cols-[100px_1fr] gap-2 py-1.5 border-b border-border last:border-b-0">
      <span className="text-text-muted text-xs">{label}</span>
      <span className="text-text text-xs break-all">{value}</span>
    </div>
  );

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onClick={onClose}>
      <div
        className="bg-surface-raised border border-border rounded-lg shadow-xl w-[400px] max-h-[80vh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-border">
          <h3 className="text-sm font-medium text-text">{t('properties.title')}</h3>
          <button onClick={onClose} className="text-text-muted hover:text-text transition-colors">
            <X size={16} />
          </button>
        </div>

        {/* Content */}
        <div className="px-4 py-3">
          {/* Basic Info */}
          <Row label={t('properties.name')} value={file.Name} />
          <Row label={t('properties.type')} value={file.IsDir ? t('properties.folder') : t('properties.file')} />
          {!file.IsDir && <Row label={t('properties.size')} value={formatBytes(file.Size)} />}
          <Row label={t('properties.modified')} value={formatDate(file.ModTime)} />
          <Row label={t('properties.path')} value={fullPath} />

          {/* Cloud Info */}
          <div className="mt-3 pt-2 border-t border-border">
            <Row label={t('properties.remote')} value={remote} />
          </div>

          {/* Hash (files only) */}
          {!file.IsDir && (
            <div className="mt-3 pt-2 border-t border-border">
              <div className="text-xs text-text-muted mb-1">{t('properties.hash')}</div>
              {hashLoading ? (
                <div className="flex items-center gap-2 py-2">
                  <Loader2 size={14} className="animate-spin text-accent" />
                  <span className="text-xs text-text-muted">{t('properties.loading')}</span>
                </div>
              ) : hashes && Object.keys(hashes).length > 0 ? (
                Object.entries(hashes).map(([type, value]) => (
                  <Row key={type} label={type.toUpperCase()} value={value} />
                ))
              ) : (
                <span className="text-xs text-text-muted">-</span>
              )}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex justify-end px-4 py-3 border-t border-border">
          <button
            onClick={onClose}
            className="px-4 py-1.5 text-xs bg-surface-overlay hover:bg-border rounded transition-colors text-text"
          >
            {t('common.close')}
          </button>
        </div>
      </div>
    </div>
  );
}
