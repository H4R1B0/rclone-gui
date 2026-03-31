import { useState, useEffect, useRef, useCallback } from 'react';
import { Lock, Fingerprint, Eye, EyeOff, ShieldCheck, AlertCircle } from 'lucide-react';
import { useT } from '../../lib/i18n';

interface LockScreenProps {
  onUnlock: () => void;
  canUseTouchID: boolean;
  useTouchID: boolean;
}

export function LockScreen({ onUnlock, canUseTouchID, useTouchID }: LockScreenProps) {
  const t = useT();
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [verifying, setVerifying] = useState(false);
  const [unlocked, setUnlocked] = useState(false);
  const [shake, setShake] = useState(false);
  const [touchIDAttempted, setTouchIDAttempted] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const triggerUnlock = useCallback(() => {
    setUnlocked(true);
    setTimeout(() => onUnlock(), 500);
  }, [onUnlock]);

  // Try Touch ID on mount
  useEffect(() => {
    if (canUseTouchID && useTouchID && !touchIDAttempted) {
      setTouchIDAttempted(true);
      handleTouchID();
    }
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (!canUseTouchID || !useTouchID) {
      inputRef.current?.focus();
    }
  }, [canUseTouchID, useTouchID]);

  const handleTouchID = async () => {
    setError('');
    try {
      const success = await window.rcloneAPI.appLockPromptTouchID();
      if (success) {
        triggerUnlock();
      } else {
        setError(t('lock.touchIDFailed'));
        inputRef.current?.focus();
      }
    } catch {
      setError(t('lock.touchIDFailed'));
      inputRef.current?.focus();
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!password.trim() || verifying) return;

    setVerifying(true);
    setError('');

    try {
      const valid = await window.rcloneAPI.appLockVerifyPassword(password);
      if (valid) {
        triggerUnlock();
      } else {
        setError(t('lock.wrongPassword'));
        setShake(true);
        setTimeout(() => setShake(false), 600);
        setPassword('');
        inputRef.current?.focus();
      }
    } catch {
      setError(t('lock.wrongPassword'));
    } finally {
      setVerifying(false);
    }
  };

  return (
    <div
      className={`fixed inset-0 z-[100] flex items-center justify-center transition-all duration-500 ${
        unlocked ? 'opacity-0 scale-110' : 'opacity-100 scale-100'
      }`}
      style={{ background: 'linear-gradient(145deg, #13132a 0%, #1e1e2e 40%, #252540 100%)' }}
    >
      {/* Animated background effects */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="lock-orb lock-orb-1" />
        <div className="lock-orb lock-orb-2" />
        <div className="lock-orb lock-orb-3" />
      </div>

      <div
        className={`relative w-[380px] flex flex-col items-center ${
          shake ? 'lock-shake' : ''
        }`}
      >
        {/* Lock icon */}
        <div className="relative mb-8">
          <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-accent/20 to-accent/5 backdrop-blur-sm border border-accent/20 flex items-center justify-center shadow-lg shadow-accent/10 lock-icon-float">
            {unlocked ? (
              <ShieldCheck size={36} className="text-success" />
            ) : (
              <Lock size={36} className="text-accent" />
            )}
          </div>
          <div className="absolute -inset-1 rounded-2xl bg-accent/10 blur-xl -z-10" />
        </div>

        {/* Title */}
        <h1 className="text-xl font-bold text-text mb-1.5 tracking-tight">
          {t('lock.title')}
        </h1>
        <p className="text-sm text-text-muted mb-8">
          {t('lock.subtitle')}
        </p>

        {/* Password form */}
        <form onSubmit={handleSubmit} className="w-full space-y-4">
          <div className="relative">
            <input
              ref={inputRef}
              type={showPassword ? 'text' : 'password'}
              value={password}
              onChange={(e) => { setPassword(e.target.value); setError(''); }}
              placeholder={t('lock.enterPassword')}
              className="w-full px-4 py-3 pr-10 rounded-xl bg-surface-overlay/80 backdrop-blur-sm border border-border focus:border-accent text-sm text-text outline-none transition-all duration-200 placeholder:text-text-muted/50"
              autoFocus={!canUseTouchID || !useTouchID}
              disabled={verifying || unlocked}
            />
            <button
              type="button"
              onClick={() => setShowPassword((v) => !v)}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-text-muted hover:text-text transition-colors"
              tabIndex={-1}
            >
              {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
            </button>
          </div>

          {/* Error message */}
          {error && (
            <div className="flex items-center gap-2 text-xs text-danger animate-fade-in">
              <AlertCircle size={14} />
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={!password.trim() || verifying || unlocked}
            className="w-full py-3 rounded-xl bg-accent hover:bg-accent-hover text-white text-sm font-medium disabled:opacity-40 disabled:cursor-not-allowed transition-all duration-200 active:scale-[0.98]"
          >
            {verifying ? (
              <span className="flex items-center justify-center gap-2">
                <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              </span>
            ) : (
              t('lock.unlock')
            )}
          </button>
        </form>

        {/* Touch ID button */}
        {canUseTouchID && useTouchID && !unlocked && (
          <button
            onClick={handleTouchID}
            className="mt-5 flex items-center gap-2.5 px-5 py-2.5 rounded-xl text-sm text-text-muted hover:text-text hover:bg-surface-overlay/50 transition-all duration-200 group"
          >
            <Fingerprint size={20} className="text-accent group-hover:scale-110 transition-transform" />
            {t('lock.useTouchID')}
          </button>
        )}
      </div>

      <style>{`
        .lock-orb {
          position: absolute;
          border-radius: 50%;
          filter: blur(80px);
          opacity: 0.15;
        }
        .lock-orb-1 {
          width: 400px;
          height: 400px;
          background: #7c6ff7;
          top: -100px;
          right: -100px;
          animation: lock-float 12s ease-in-out infinite;
        }
        .lock-orb-2 {
          width: 300px;
          height: 300px;
          background: #4ade80;
          bottom: -80px;
          left: -80px;
          animation: lock-float 15s ease-in-out infinite reverse;
        }
        .lock-orb-3 {
          width: 200px;
          height: 200px;
          background: #9189fa;
          top: 40%;
          left: 30%;
          animation: lock-float 10s ease-in-out infinite 2s;
        }
        @keyframes lock-float {
          0%, 100% { transform: translate(0, 0) scale(1); }
          33% { transform: translate(30px, -20px) scale(1.05); }
          66% { transform: translate(-20px, 20px) scale(0.95); }
        }
        .lock-icon-float {
          animation: lock-icon-bob 3s ease-in-out infinite;
        }
        @keyframes lock-icon-bob {
          0%, 100% { transform: translateY(0); }
          50% { transform: translateY(-6px); }
        }
        .lock-shake {
          animation: lock-shake 0.6s ease-in-out;
        }
        @keyframes lock-shake {
          0%, 100% { transform: translateX(0); }
          10%, 50%, 90% { transform: translateX(-8px); }
          30%, 70% { transform: translateX(8px); }
        }
        .animate-fade-in {
          animation: lock-fade-in 0.3s ease-out;
        }
        @keyframes lock-fade-in {
          from { opacity: 0; transform: translateY(-4px); }
          to { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </div>
  );
}
