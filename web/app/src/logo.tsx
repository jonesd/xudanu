interface LogoProps {
  size?: number;
}

export function Logo({ size = 20 }: LogoProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 32 32"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <defs>
        <linearGradient id="xudanu-grad" x1="0" y1="0" x2="32" y2="32">
          <stop offset="0%" stopColor="#d97706" />
          <stop offset="100%" stopColor="#e11d48" />
        </linearGradient>
      </defs>
      <rect
        x="4"
        y="6"
        width="16"
        height="20"
        rx="3"
        stroke="url(#xudanu-grad)"
        strokeWidth="2.5"
        fill="none"
      />
      <rect
        x="12"
        y="3"
        width="16"
        height="20"
        rx="3"
        stroke="url(#xudanu-grad)"
        strokeWidth="2.5"
        fill="var(--bg-surface, #22222e)"
        fillOpacity="0.6"
      />
      <line
        x1="10"
        y1="14"
        x2="22"
        y2="14"
        stroke="url(#xudanu-grad)"
        strokeWidth="2"
        strokeLinecap="round"
      />
      <circle cx="10" cy="14" r="2" fill="url(#xudanu-grad)" />
      <circle cx="22" cy="14" r="2" fill="url(#xudanu-grad)" />
    </svg>
  );
}
