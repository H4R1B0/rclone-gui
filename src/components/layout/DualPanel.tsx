import { useState, useCallback } from 'react';
import { Panel } from './Panel';
import { GripVertical } from 'lucide-react';

export function DualPanel() {
  const [splitPercent, setSplitPercent] = useState(50);
  const [dragging, setDragging] = useState(false);

  const onMouseDown = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    setDragging(true);
    const onMove = (ev: MouseEvent) => {
      const container = document.getElementById('dual-panel-container');
      if (!container) return;
      const rect = container.getBoundingClientRect();
      const pct = ((ev.clientX - rect.left) / rect.width) * 100;
      setSplitPercent(Math.max(20, Math.min(80, pct)));
    };
    const onUp = () => {
      setDragging(false);
      window.removeEventListener('mousemove', onMove);
      window.removeEventListener('mouseup', onUp);
    };
    window.addEventListener('mousemove', onMove);
    window.addEventListener('mouseup', onUp);
  }, []);

  return (
    <div
      id="dual-panel-container"
      className="flex-1 flex min-h-0 h-full"
      style={{ cursor: dragging ? 'col-resize' : undefined }}
    >
      <div style={{ width: `${splitPercent}%` }} className="min-w-0 h-full">
        <Panel side="left" />
      </div>
      <div
        className="w-1 bg-border hover:bg-accent cursor-col-resize flex items-center justify-center flex-shrink-0 transition-colors"
        onMouseDown={onMouseDown}
      >
        <GripVertical size={12} className="text-text-muted" />
      </div>
      <div style={{ width: `${100 - splitPercent}%` }} className="min-w-0 h-full">
        <Panel side="right" />
      </div>
    </div>
  );
}
