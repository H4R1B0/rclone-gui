import type { Config } from 'tailwindcss';

export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        surface: {
          DEFAULT: '#1e1e2e',
          raised: '#252536',
          overlay: '#2a2a3c',
        },
        border: {
          DEFAULT: '#3b3b52',
          focus: '#7c6ff7',
        },
        accent: {
          DEFAULT: '#7c6ff7',
          hover: '#9189fa',
          muted: '#7c6ff730',
        },
        text: {
          DEFAULT: '#e0e0e8',
          muted: '#9090a8',
          inverse: '#1e1e2e',
        },
        success: '#4ade80',
        warning: '#facc15',
        danger: '#f87171',
      },
    },
  },
  plugins: [],
} satisfies Config;
