// Real brand SVG icons from simple-icons, mapped to rclone provider prefixes.
// For providers without a brand icon, we fall back to a generic cloud SVG.

import {
  siGoogledrive, siDropbox, siBox, siMega, siNextcloud, siOwncloud,
  siBackblaze, siDigitalocean, siCloudflare, siHetzner, siWasabi, siMinio,
  siGooglecloudstorage, siProtondrive, siSeafile, siZoho, siYandexcloud,
} from 'simple-icons';

export interface ProviderIcon {
  svg: string;    // SVG path data (d attribute)
  color: string;  // hex color
  title: string;  // display name
}

// simple-icons entry → our format
function si(icon: { path: string; hex: string; title: string }): ProviderIcon {
  return { svg: icon.path, color: `#${icon.hex}`, title: icon.title };
}

// Generic fallback icons (hand-drawn simple SVG paths for 24x24 viewBox)
const genericCloud: ProviderIcon = {
  svg: 'M6.341 13.581c-2.335-.264-4.137-2.178-4.341-4.545C1.825 6.498 3.898 4.2 6.5 4.2c.419 0 .831.054 1.23.16C8.721 2.342 10.65 1 12.903 1c2.98 0 5.43 2.208 5.826 5.075C20.56 6.595 22 8.34 22 10.429c0 2.41-1.93 4.37-4.328 4.457H6.341z',
  color: '#8B8B9A',
  title: 'Cloud',
};

const genericServer: ProviderIcon = {
  svg: 'M4 1h16a2 2 0 0 1 2 2v4a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V3a2 2 0 0 1 2-2zm0 14h16a2 2 0 0 1 2 2v4a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2v-4a2 2 0 0 1 2-2zM6 4.5a1.5 1.5 0 1 0 0 3 1.5 1.5 0 0 0 0-3zm0 14a1.5 1.5 0 1 0 0 3 1.5 1.5 0 0 0 0-3z',
  color: '#4EAA25',
  title: 'Server',
};

const genericLock: ProviderIcon = {
  svg: 'M12 1a5 5 0 0 0-5 5v4H5a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-8a2 2 0 0 0-2-2h-2V6a5 5 0 0 0-5-5zm-3 5a3 3 0 1 1 6 0v4H9V6zm3 9a2 2 0 1 1 0 4 2 2 0 0 1 0-4z',
  color: '#7C6FF7',
  title: 'Encrypted',
};

const genericDisk: ProviderIcon = {
  svg: 'M4 1h12l5 5v14a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V3a2 2 0 0 1 2-2zm8 18a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM6 4v5h9V4H6z',
  color: '#8B8B9A',
  title: 'Storage',
};

const genericGlobe: ProviderIcon = {
  svg: 'M12 1C5.925 1 1 5.925 1 12s4.925 11 11 11 11-4.925 11-11S18.075 1 12 1zM2.513 12h4.5c.07-2.12.52-4.1 1.28-5.73A9.014 9.014 0 0 0 2.513 12zm9.49-9.475c-1.14 1.47-2.03 3.54-2.34 5.975h4.67c-.31-2.44-1.2-4.51-2.33-5.975zM12.003 1.525zM14.694 12H9.31c.08 2.18.57 4.2 1.37 5.82a12.1 12.1 0 0 0 2.65 0c.8-1.62 1.29-3.64 1.37-5.82zM7.013 12h-4.5a9.014 9.014 0 0 0 5.78 5.73c-.76-1.63-1.21-3.61-1.28-5.73zm14.474 0h-4.5c-.07 2.12-.52 4.1-1.28 5.73A9.014 9.014 0 0 0 21.487 12zm-4.5-1.5h4.5a9.014 9.014 0 0 0-5.78-5.73c.76 1.63 1.21 3.61 1.28 5.73z',
  color: '#E44D26',
  title: 'Web',
};

// OneDrive SVG path (manually drawn, recognizable shape)
const onedrive: ProviderIcon = {
  svg: 'M10.077 8.677a5.24 5.24 0 0 1 8.545 2.273 4.073 4.073 0 0 1-.29 7.95H5.354a3.987 3.987 0 0 1-2.03-7.426 4.727 4.727 0 0 1 6.753-2.797z',
  color: '#0078D4',
  title: 'OneDrive',
};

const amazonS3: ProviderIcon = {
  svg: 'M12 2L2 7v10l10 5 10-5V7L12 2zm0 2.24L19.1 7.6 12 11.52 4.9 7.6 12 4.24zM4 9.04l7 3.5V19l-7-3.5V9.04zm10 9.96v-6.46l7-3.5V15.5L14 19z',
  color: '#FF9900',
  title: 'Amazon S3',
};

const azure: ProviderIcon = {
  svg: 'M13.053 1L5.895 8.458l-3.9 6.9h4.9l-5.9 7.642h18.91L13.053 1zM8.65 16.558l4.45-5.2 3.3 7.642h-7.75z',
  color: '#0089D6',
  title: 'Azure',
};

const pcloud: ProviderIcon = {
  svg: 'M19.35 10.04A7.49 7.49 0 0 0 12 4a7.48 7.48 0 0 0-6.62 4.04A5.994 5.994 0 0 0 0 14a6 6 0 0 0 6 6h13a5 5 0 0 0 .35-9.96z',
  color: '#0FA8E0',
  title: 'pCloud',
};

const mega2: ProviderIcon = si(siMega);

// Map rclone provider prefix → icon
const mapping: Record<string, ProviderIcon> = {
  // Major cloud
  drive:           si(siGoogledrive),
  onedrive:        onedrive,
  dropbox:         si(siDropbox),
  box:             si(siBox),
  mega:            mega2,
  pcloud:          pcloud,

  // Self-hosted
  nextcloud:       si(siNextcloud),
  owncloud:        si(siOwncloud),
  seafile:         si(siSeafile),

  // S3-compatible
  s3:              amazonS3,
  b2:              si(siBackblaze),
  wasabi:          si(siWasabi),
  minio:           si(siMinio),

  // Cloud infra
  gcs:             si(siGooglecloudstorage),
  azureblob:       azure,
  azurefiles:      azure,
  digitalocean:    si(siDigitalocean),
  cloudflare:      si(siCloudflare),
  hetzner:         si(siHetzner),

  // Privacy
  protondrive:     si(siProtondrive),
  crypt:           genericLock,

  // Protocols
  sftp:            genericServer,
  ftp:             { ...genericServer, color: '#76A0DA', title: 'FTP' },
  webdav:          { ...genericGlobe, color: '#E44D26', title: 'WebDAV' },
  http:            { ...genericGlobe, color: '#4285F4', title: 'HTTP' },
  smb:             { ...genericServer, color: '#0078D4', title: 'SMB' },

  // Regional
  yandex:          si(siYandexcloud),
  mailru:          { ...genericCloud, color: '#005FF9', title: 'Mail.ru' },
  zoho:            si(siZoho),

  // Virtual
  local:           genericDisk,
  alias:           { ...genericDisk, color: '#7C6FF7', title: 'Alias' },
  union:           { ...genericDisk, color: '#E67E22', title: 'Union' },
  combine:         { ...genericDisk, color: '#E67E22', title: 'Combine' },
  compress:        { ...genericDisk, color: '#27AE60', title: 'Compress' },
  chunker:         { ...genericDisk, color: '#3498DB', title: 'Chunker' },
  hasher:          { ...genericLock, color: '#9B59B6', title: 'Hasher' },

  // Others with brand colors
  swift:           { ...genericCloud, color: '#C42126', title: 'OpenStack Swift' },
  hubic:           { ...genericCloud, color: '#003B6F', title: 'Hubic' },
  jottacloud:      { ...genericCloud, color: '#27AE60', title: 'Jottacloud' },
  koofr:           { ...genericCloud, color: '#00A651', title: 'Koofr' },
  putio:           { ...genericCloud, color: '#E8403A', title: 'put.io' },
  sharefile:       { ...genericCloud, color: '#56B349', title: 'ShareFile' },
  fichier:         { ...genericCloud, color: '#2B6EB5', title: '1Fichier' },
  sugarsync:       { ...genericCloud, color: '#4A9CDD', title: 'SugarSync' },
  hidrive:         { ...genericCloud, color: '#005BAC', title: 'HiDrive' },
  pikpak:          { ...genericCloud, color: '#5979F2', title: 'PikPak' },
  opendrive:       { ...genericCloud, color: '#0098FF', title: 'OpenDrive' },
  linkbox:         { ...genericCloud, color: '#2E8DF5', title: 'Linkbox' },
  gofile:          { ...genericCloud, color: '#00B4D8', title: 'GoFile' },
  quatrix:         { ...genericCloud, color: '#3B82F6', title: 'Quatrix' },
  premiumizeme:    { ...genericCloud, color: '#D4A843', title: 'Premiumize.me' },
  imagekit:        { ...genericCloud, color: '#3B5CFF', title: 'ImageKit' },
  sia:             { ...genericCloud, color: '#1ED660', title: 'Sia' },
  storj:           { ...genericCloud, color: '#2683FF', title: 'Storj' },
  internetarchive: { ...genericCloud, color: '#428BCA', title: 'Internet Archive' },
  filefabric:      { ...genericCloud, color: '#FF6B35', title: 'FileFabric' },
  uptobox:         { ...genericCloud, color: '#22A3C6', title: 'Uptobox' },
  ulozto:          { ...genericCloud, color: '#ED1C24', title: 'Uloz.to' },
  memory:          { ...genericDisk, color: '#E74C3C', title: 'Memory' },
  cache:           { ...genericDisk, color: '#F1C40F', title: 'Cache' },
  hdfs:            { ...genericServer, color: '#FF7E00', title: 'HDFS' },
};

export function getProviderIcon(prefix: string): ProviderIcon {
  return mapping[prefix] ?? { ...genericCloud, title: prefix || 'Cloud' };
}
