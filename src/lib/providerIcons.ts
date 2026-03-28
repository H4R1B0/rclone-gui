import type { LucideIcon } from 'lucide-react';
import {
  Cloud, HardDrive, Database, Server, Globe, Shield, Lock,
  Folder, Upload, Box, Mail, Smartphone, Wifi, Archive,
} from 'lucide-react';

// Map rclone provider prefix → icon + color
interface ProviderMeta {
  icon: LucideIcon;
  color: string;
}

const specific: Record<string, ProviderMeta> = {
  drive:       { icon: Cloud,      color: '#4285F4' },  // Google Drive
  onedrive:    { icon: Cloud,      color: '#0078D4' },  // OneDrive
  dropbox:     { icon: Box,        color: '#0061FF' },  // Dropbox
  s3:          { icon: Database,   color: '#FF9900' },  // Amazon S3
  b2:          { icon: Database,   color: '#E03C31' },  // Backblaze B2
  box:         { icon: Box,        color: '#0061D5' },  // Box
  mega:        { icon: Shield,     color: '#D9272E' },  // Mega
  pcloud:      { icon: Cloud,      color: '#0FA8E0' },  // pCloud
  sftp:        { icon: Server,     color: '#4EAA25' },  // SFTP
  ftp:         { icon: Server,     color: '#76A0DA' },  // FTP
  webdav:      { icon: Globe,      color: '#E44D26' },  // WebDAV
  nextcloud:   { icon: Cloud,      color: '#0082C9' },  // Nextcloud
  swift:       { icon: Database,   color: '#C42126' },  // OpenStack Swift
  azureblob:   { icon: Database,   color: '#0089D6' },  // Azure Blob
  gcs:         { icon: Database,   color: '#4285F4' },  // Google Cloud Storage
  crypt:       { icon: Lock,       color: '#7C6FF7' },  // Crypt
  local:       { icon: HardDrive,  color: '#8B8B9A' },  // Local
  alias:       { icon: Folder,     color: '#8B8B9A' },  // Alias
  union:       { icon: Archive,    color: '#8B8B9A' },  // Union
  compress:    { icon: Archive,    color: '#8B8B9A' },  // Compress
  chunker:     { icon: Archive,    color: '#8B8B9A' },  // Chunker
  http:        { icon: Globe,      color: '#E44D26' },  // HTTP
  yandex:      { icon: Cloud,      color: '#FFCC00' },  // Yandex
  mailru:      { icon: Mail,       color: '#005FF9' },  // Mail.ru
  jottacloud:  { icon: Cloud,      color: '#27AE60' },  // Jottacloud
  koofr:       { icon: Cloud,      color: '#00A651' },  // Koofr
  putio:       { icon: Upload,     color: '#E8403A' },  // put.io
  sharefile:   { icon: Cloud,      color: '#56B349' },  // Citrix ShareFile
  fichier:     { icon: Cloud,      color: '#2B6EB5' },  // 1Fichier
  premiumizeme:{ icon: Cloud,      color: '#D4A843' },  // Premiumize.me
  seafile:     { icon: Cloud,      color: '#F58B1F' },  // Seafile
  uptobox:     { icon: Upload,     color: '#22A3C6' },  // Uptobox
  zoho:        { icon: Cloud,      color: '#C8202B' },  // Zoho WorkDrive
  hdfs:        { icon: Database,   color: '#FF7E00' },  // Hadoop
  sia:         { icon: Shield,     color: '#1ED660' },  // Sia
  storj:       { icon: Shield,     color: '#2683FF' },  // Storj
  sugarsync:   { icon: Cloud,      color: '#4A9CDD' },  // SugarSync
  tardigrade:  { icon: Shield,     color: '#2683FF' },  // Tardigrade (Storj)
  hidrive:     { icon: Cloud,      color: '#005BAC' },  // HiDrive
  internetarchive: { icon: Archive, color: '#428BCA' },  // Internet Archive
  smb:         { icon: Wifi,       color: '#8B8B9A' },  // SMB
  filefabric:  { icon: Cloud,      color: '#FF6B35' },  // FileFabric
  combine:     { icon: Archive,    color: '#8B8B9A' },  // Combine
  protondrive: { icon: Shield,     color: '#6D4AFF' },  // Proton Drive
  imagekit:    { icon: Smartphone, color: '#3B5CFF' },  // ImageKit
  linkbox:     { icon: Cloud,      color: '#2E8DF5' },  // Linkbox
  pikpak:      { icon: Cloud,      color: '#5979F2' },  // PikPak
  gofile:      { icon: Upload,     color: '#00B4D8' },  // GoFile
  uloz:        { icon: Upload,     color: '#ED1C24' },  // Uloz.to
  quatrix:     { icon: Cloud,      color: '#3B82F6' },  // Quatrix
  opendrive:   { icon: Cloud,      color: '#0098FF' },  // OpenDrive
};

const fallback: ProviderMeta = { icon: Cloud, color: '#8B8B9A' };

export function getProviderMeta(prefix: string): ProviderMeta {
  return specific[prefix] ?? fallback;
}
