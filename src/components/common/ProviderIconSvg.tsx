import { getProviderIcon } from '../../lib/providerIcons';

interface ProviderIconSvgProps {
  prefix: string;
  size?: number;
  className?: string;
}

export function ProviderIconSvg({ prefix, size = 20, className }: ProviderIconSvgProps) {
  const icon = getProviderIcon(prefix);

  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      width={size}
      height={size}
      fill={icon.color}
      className={className}
      role="img"
      aria-label={icon.title}
    >
      <path d={icon.svg} />
    </svg>
  );
}
