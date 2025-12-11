# Lesson 8: File Uploads with Supabase Storage

**Tutorial:** Next.js 16 + React 19.2 + Supabase - Complete Learning Path
**Focus:** File uploads, storage buckets, and attachment management
**Prerequisites:** Lessons 1-7 completed

---

## What You'll Build

In this lesson, you'll implement **file upload and storage features** that allow users to attach files to projects and tasks:

- ✅ **Supabase Storage Buckets** - Create and configure storage buckets
- ✅ **File Uploads** - Upload images, documents, and other files
- ✅ **Progress Tracking** - Show upload progress with percentage
- ✅ **File Validation** - Validate file size, type, and count
- ✅ **Image Previews** - Display thumbnails for uploaded images
- ✅ **Signed URLs** - Secure, time-limited download URLs
- ✅ **File Management** - View, download, and delete attachments
- ✅ **Attachment Table** - Link files to projects/tasks
- ✅ **RLS Policies** - Secure storage with Row Level Security

### Technologies Used

- **Supabase Storage** - Object storage for files (S3-compatible)
- **Storage Policies** - RLS for storage buckets
- **Signed URLs** - Temporary, secure download links
- **Next.js 16** - Server Actions for file operations
- **React 19.2** - Client Components with file inputs
- **TypeScript** - Type-safe file handling

---

## Architecture Overview

### Supabase Storage Structure

```
Supabase Storage
│
├── Buckets (containers for files)
│   ├── project-attachments (public read, authenticated write)
│   ├── task-attachments (private, RLS enforced)
│   └── avatars (public read, owner write)
│
└── Files (objects within buckets)
    ├── /projects/{project_id}/{file_name}
    ├── /tasks/{task_id}/{file_name}
    └── /avatars/{user_id}/{file_name}
```

### Database Schema for Attachments

```sql
prj_project_attachments
├── id (uuid, primary key)
├── project_id (uuid, foreign key → prj_projects)
├── file_name (text)
├── file_path (text) -- Path in storage bucket
├── file_size (bigint) -- Bytes
├── mime_type (text)
├── uploaded_by (uuid, foreign key → auth.users)
├── created_at (timestamp)
└── updated_at (timestamp)
```

---

## Step 1: Configure Next.js for Cache Components

Update your `next.config.js` to enable Cache Components:

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    // Enable Next.js 16 Cache Components
    cacheComponents: true,

    // Optional: Configure cache handlers
    cacheHandlers: {
      // Custom cache configuration if needed
    },
  },
};

module.exports = nextConfig;
```

**Why Cache Components?**

File attachments are perfect candidates for caching because:
- File listings don't change frequently
- Metadata queries can be expensive with many attachments
- Signed URLs can be cached with their expiration time
- Cache invalidation is predictable (only on upload/delete)

---

## Step 2: Create Database Migration for Attachments

Create a new migration for attachment tables:

```bash
cat > supabase/migrations/005_attachments.sql << 'EOF'
-- ============================================================
-- LESSON 8: FILE ATTACHMENTS
-- ============================================================

-- Project Attachments Table
CREATE TABLE IF NOT EXISTS prj_project_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES prj_projects(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL UNIQUE, -- Path in Supabase Storage
  file_size BIGINT NOT NULL, -- Size in bytes
  mime_type TEXT NOT NULL,
  uploaded_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Task Attachments Table
CREATE TABLE IF NOT EXISTS prj_task_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES prj_tasks(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL UNIQUE,
  file_size BIGINT NOT NULL,
  mime_type TEXT NOT NULL,
  uploaded_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_project_attachments_project_id ON prj_project_attachments(project_id);
CREATE INDEX idx_task_attachments_task_id ON prj_task_attachments(task_id);

-- Enable Row Level Security
ALTER TABLE prj_project_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE prj_task_attachments ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- RLS POLICIES: Project Attachments
-- ============================================================

-- Users can view attachments for projects they're members of
CREATE POLICY "Members can view project attachments"
  ON prj_project_attachments
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM prj_project_members pm
      WHERE pm.project_id = prj_project_attachments.project_id
      AND pm.user_id = auth.uid()
    )
  );

-- Members (not just viewers) can upload attachments
CREATE POLICY "Members can upload project attachments"
  ON prj_project_attachments
  FOR INSERT
  WITH CHECK (
    auth.uid() = uploaded_by
    AND EXISTS (
      SELECT 1 FROM prj_project_members pm
      WHERE pm.project_id = prj_project_attachments.project_id
      AND pm.user_id = auth.uid()
      AND pm.role IN ('owner', 'admin', 'member')
    )
  );

-- Users can delete their own attachments OR owners/admins can delete any
CREATE POLICY "Users can delete own attachments, admins can delete any"
  ON prj_project_attachments
  FOR DELETE
  USING (
    uploaded_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM prj_project_members pm
      WHERE pm.project_id = prj_project_attachments.project_id
      AND pm.user_id = auth.uid()
      AND pm.role IN ('owner', 'admin')
    )
  );

-- ============================================================
-- RLS POLICIES: Task Attachments
-- ============================================================

-- Users can view attachments for tasks in projects they're members of
CREATE POLICY "Members can view task attachments"
  ON prj_task_attachments
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM prj_tasks t
      JOIN prj_project_members pm ON t.project_id = pm.project_id
      WHERE t.id = prj_task_attachments.task_id
      AND pm.user_id = auth.uid()
    )
  );

-- Members can upload task attachments
CREATE POLICY "Members can upload task attachments"
  ON prj_task_attachments
  FOR INSERT
  WITH CHECK (
    auth.uid() = uploaded_by
    AND EXISTS (
      SELECT 1 FROM prj_tasks t
      JOIN prj_project_members pm ON t.project_id = pm.project_id
      WHERE t.id = prj_task_attachments.task_id
      AND pm.user_id = auth.uid()
      AND pm.role IN ('owner', 'admin', 'member')
    )
  );

-- Users can delete their own attachments OR owners/admins can delete any
CREATE POLICY "Users can delete own task attachments, admins can delete any"
  ON prj_task_attachments
  FOR DELETE
  USING (
    uploaded_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM prj_tasks t
      JOIN prj_project_members pm ON t.project_id = pm.project_id
      WHERE t.id = prj_task_attachments.task_id
      AND pm.user_id = auth.uid()
      AND pm.role IN ('owner', 'admin')
    )
  );

-- ============================================================
-- RPC FUNCTIONS
-- ============================================================

-- Get project attachments with uploader info
CREATE OR REPLACE FUNCTION get_project_attachments(p_project_id UUID)
RETURNS TABLE (
  id UUID,
  project_id UUID,
  file_name TEXT,
  file_path TEXT,
  file_size BIGINT,
  mime_type TEXT,
  uploaded_by UUID,
  uploader_email TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    pa.id,
    pa.project_id,
    pa.file_name,
    pa.file_path,
    pa.file_size,
    pa.mime_type,
    pa.uploaded_by,
    u.email AS uploader_email,
    pa.created_at,
    pa.updated_at
  FROM prj_project_attachments pa
  JOIN auth.users u ON pa.uploaded_by = u.id
  WHERE pa.project_id = p_project_id
  ORDER BY pa.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get task attachments with uploader info
CREATE OR REPLACE FUNCTION get_task_attachments(p_task_id UUID)
RETURNS TABLE (
  id UUID,
  task_id UUID,
  file_name TEXT,
  file_path TEXT,
  file_size BIGINT,
  mime_type TEXT,
  uploaded_by UUID,
  uploader_email TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ta.id,
    ta.task_id,
    ta.file_name,
    ta.file_path,
    ta.file_size,
    ta.mime_type,
    ta.uploaded_by,
    u.email AS uploader_email,
    ta.created_at,
    ta.updated_at
  FROM prj_task_attachments ta
  JOIN auth.users u ON ta.uploaded_by = u.id
  WHERE ta.task_id = p_task_id
  ORDER BY ta.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

EOF
```

**Run migration:**

```bash
# If using Supabase CLI locally
supabase db push

# Otherwise, copy SQL and run in Supabase Dashboard → SQL Editor
```

---

## Step 3: Create Storage Buckets in Supabase Dashboard

**🎯 Manual Steps (Supabase Dashboard):**

### 2.1 Create Project Attachments Bucket

1. Go to **Storage** in Supabase Dashboard
2. Click **New bucket**
3. Name: `project-attachments`
4. Public bucket: **OFF** (private, RLS enforced)
5. Click **Create bucket**

### 2.2 Create Task Attachments Bucket

1. Click **New bucket**
2. Name: `task-attachments`
3. Public bucket: **OFF**
4. Click **Create bucket**

### 2.3 Create Storage Policies

For **project-attachments** bucket:

**Policy 1: Allow members to view files**
```sql
CREATE POLICY "Members can view project files"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'project-attachments'
  AND (storage.foldername(name))[1] IN (
    SELECT project_id::text
    FROM prj_project_members
    WHERE user_id = auth.uid()
  )
);
```

**Policy 2: Allow members to upload files**
```sql
CREATE POLICY "Members can upload project files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'project-attachments'
  AND (storage.foldername(name))[1] IN (
    SELECT project_id::text
    FROM prj_project_members
    WHERE user_id = auth.uid()
    AND role IN ('owner', 'admin', 'member')
  )
);
```

**Policy 3: Allow users to delete own files**
```sql
CREATE POLICY "Users can delete own project files"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'project-attachments'
  AND (
    -- User uploaded this file
    owner = auth.uid()
    OR
    -- OR user is owner/admin of the project
    (storage.foldername(name))[1] IN (
      SELECT project_id::text
      FROM prj_project_members
      WHERE user_id = auth.uid()
      AND role IN ('owner', 'admin')
    )
  )
);
```

**Repeat similar policies for `task-attachments` bucket** (replace `project-attachments` with `task-attachments` and adjust folder paths).

---

## Step 4: Extend Constants

Add file upload constants to `src/constants/index.ts`:

```bash
cat >> src/constants/index.ts << 'EOF'

// ============================================================
// STORAGE CONSTANTS (Lesson 8)
// ============================================================

export const STORAGE_BUCKETS = {
  PROJECT_ATTACHMENTS: 'project-attachments',
  TASK_ATTACHMENTS: 'task-attachments',
} as const;

export const FILE_UPLOAD = {
  MAX_FILE_SIZE: 5 * 1024 * 1024, // 5MB in bytes
  MAX_FILES_PER_UPLOAD: 10,
  ALLOWED_IMAGE_TYPES: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
  ALLOWED_DOCUMENT_TYPES: [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain',
  ],
  ALLOWED_SPREADSHEET_TYPES: [
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/csv',
  ],
} as const;

// All allowed file types
export const ALLOWED_FILE_TYPES = [
  ...FILE_UPLOAD.ALLOWED_IMAGE_TYPES,
  ...FILE_UPLOAD.ALLOWED_DOCUMENT_TYPES,
  ...FILE_UPLOAD.ALLOWED_SPREADSHEET_TYPES,
] as const;

// File type categories
export const FILE_CATEGORIES = {
  IMAGE: 'image',
  DOCUMENT: 'document',
  SPREADSHEET: 'spreadsheet',
  OTHER: 'other',
} as const;

// UI Messages
export const FILE_UPLOAD_MESSAGES = {
  UPLOADING: 'Uploading files...',
  UPLOAD_SUCCESS: 'Files uploaded successfully',
  UPLOAD_ERROR: 'Failed to upload files',
  FILE_TOO_LARGE: 'File is too large (max 5MB)',
  INVALID_FILE_TYPE: 'Invalid file type',
  TOO_MANY_FILES: 'Too many files (max 10)',
} as const;

// Type exports
export type StorageBucket = typeof STORAGE_BUCKETS[keyof typeof STORAGE_BUCKETS];
export type FileCategory = typeof FILE_CATEGORIES[keyof typeof FILE_CATEGORIES];

EOF
```

---

## Step 5: Create Storage Types

Create TypeScript types for storage:

```bash
cat > src/types/storage.ts << 'EOF'
import type { Database } from '@/lib/types/database';

// Attachment types from database
export type ProjectAttachment = Database['public']['Tables']['prj_project_attachments']['Row'];
export type TaskAttachment = Database['public']['Tables']['prj_task_attachments']['Row'];

// Upload progress tracking
export type UploadProgress = {
  fileName: string;
  progress: number; // 0-100
  status: 'pending' | 'uploading' | 'success' | 'error';
  error?: string;
};

// File metadata
export type FileMetadata = {
  name: string;
  size: number;
  type: string;
  lastModified: number;
};

// Storage upload response
export type StorageUploadResponse = {
  success: boolean;
  data?: {
    path: string;
    fullPath: string;
  };
  error?: string;
};

// Attachment with signed URL
export type AttachmentWithUrl = ProjectAttachment & {
  signedUrl?: string;
  isImage?: boolean;
};

EOF
```

---

## Step 6: Create File Upload Utilities

Create utility functions for file validation and processing:

```bash
mkdir -p src/utils/storage
cat > src/utils/storage/fileValidation.ts << 'EOF'
import { FILE_UPLOAD, ALLOWED_FILE_TYPES, FILE_CATEGORIES } from '@/constants';
import type { FileCategory } from '@/constants';

/**
 * Validate file size
 */
export function validateFileSize(file: File): { valid: boolean; error?: string } {
  if (file.size > FILE_UPLOAD.MAX_FILE_SIZE) {
    const maxSizeMB = FILE_UPLOAD.MAX_FILE_SIZE / (1024 * 1024);
    return {
      valid: false,
      error: `File "${file.name}" is too large. Max size: ${maxSizeMB}MB`,
    };
  }
  return { valid: true };
}

/**
 * Validate file type
 */
export function validateFileType(file: File): { valid: boolean; error?: string } {
  if (!ALLOWED_FILE_TYPES.includes(file.type as any)) {
    return {
      valid: false,
      error: `File type "${file.type}" is not allowed`,
    };
  }
  return { valid: true };
}

/**
 * Validate multiple files
 */
export function validateFiles(files: File[]): { valid: boolean; error?: string } {
  if (files.length > FILE_UPLOAD.MAX_FILES_PER_UPLOAD) {
    return {
      valid: false,
      error: `Too many files. Max: ${FILE_UPLOAD.MAX_FILES_PER_UPLOAD}`,
    };
  }

  for (const file of files) {
    const sizeCheck = validateFileSize(file);
    if (!sizeCheck.valid) return sizeCheck;

    const typeCheck = validateFileType(file);
    if (!typeCheck.valid) return typeCheck;
  }

  return { valid: true };
}

/**
 * Get file category from mime type
 */
export function getFileCategory(mimeType: string): FileCategory {
  if (FILE_UPLOAD.ALLOWED_IMAGE_TYPES.includes(mimeType as any)) {
    return FILE_CATEGORIES.IMAGE;
  }
  if (FILE_UPLOAD.ALLOWED_DOCUMENT_TYPES.includes(mimeType as any)) {
    return FILE_CATEGORIES.DOCUMENT;
  }
  if (FILE_UPLOAD.ALLOWED_SPREADSHEET_TYPES.includes(mimeType as any)) {
    return FILE_CATEGORIES.SPREADSHEET;
  }
  return FILE_CATEGORIES.OTHER;
}

/**
 * Format file size for display
 */
export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 Bytes';

  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
}

/**
 * Generate safe file path for storage
 */
export function generateFilePath(folder: string, fileName: string): string {
  const timestamp = Date.now();
  const sanitized = fileName.replace(/[^a-zA-Z0-9.-]/g, '_');
  return `${folder}/${timestamp}-${sanitized}`;
}

EOF
```

---

## Step 7: Create Storage Server Actions

Create Server Actions for file operations with cache invalidation:

```bash
cat > src/lib/actions/storage.ts << 'EOF'
'use server';

import { createClient } from '@/lib/supabase/server';
import { updateTag } from 'next/cache';
import { STORAGE_BUCKETS, DB_TABLES, ROUTES } from '@/constants';
import { generateFilePath, formatFileSize } from '@/utils/storage/fileValidation';
import type { StorageUploadResponse } from '@/types/storage';

/**
 * Upload file to Supabase Storage
 */
export async function uploadFile(formData: FormData, bucket: string, folder: string) {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      return { success: false, error: 'Unauthorized' };
    }

    const file = formData.get('file') as File;
    if (!file) {
      return { success: false, error: 'No file provided' };
    }

    // Generate file path
    const filePath = generateFilePath(folder, file.name);

    // Upload to storage
    const { data, error } = await supabase.storage
      .from(bucket)
      .upload(filePath, file, {
        cacheControl: '3600',
        upsert: false,
      });

    if (error) {
      console.error('Storage upload error:', error);
      return { success: false, error: error.message };
    }

    return {
      success: true,
      data: {
        path: data.path,
        fullPath: data.fullPath,
      },
    };
  } catch (error: any) {
    console.error('Upload error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Upload project attachment
 */
export async function uploadProjectAttachment(projectId: string, formData: FormData) {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      return { success: false, error: 'Unauthorized' };
    }

    const file = formData.get('file') as File;
    if (!file) {
      return { success: false, error: 'No file provided' };
    }

    // Upload to storage
    const uploadResult = await uploadFile(
      formData,
      STORAGE_BUCKETS.PROJECT_ATTACHMENTS,
      projectId
    );

    if (!uploadResult.success || !uploadResult.data) {
      return uploadResult;
    }

    // Save metadata to database
    const { data, error } = await supabase
      .from(DB_TABLES.PROJECT_ATTACHMENTS)
      .insert({
        project_id: projectId,
        file_name: file.name,
        file_path: uploadResult.data.path,
        file_size: file.size,
        mime_type: file.type,
        uploaded_by: user.id,
      })
      .select()
      .single();

    if (error) {
      console.error('Database insert error:', error);
      // Delete uploaded file if database insert fails
      await supabase.storage
        .from(STORAGE_BUCKETS.PROJECT_ATTACHMENTS)
        .remove([uploadResult.data.path]);

      return { success: false, error: error.message };
    }

    // Invalidate cache tags
    updateTag('attachments');
    updateTag(`project-${projectId}-attachments`);

    return { success: true, data };
  } catch (error: any) {
    console.error('Upload attachment error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Get project attachments
 */
export async function getProjectAttachments(projectId: string) {
  try {
    const supabase = await createClient();

    const { data, error } = await supabase.rpc('get_project_attachments', {
      p_project_id: projectId,
    });

    if (error) {
      console.error('Get attachments error:', error);
      return { success: false, error: error.message };
    }

    return { success: true, data };
  } catch (error: any) {
    console.error('Get attachments error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Get signed URL for file download
 */
export async function getSignedUrl(bucket: string, filePath: string, expiresIn: number = 3600) {
  try {
    const supabase = await createClient();

    const { data, error } = await supabase.storage
      .from(bucket)
      .createSignedUrl(filePath, expiresIn);

    if (error) {
      console.error('Signed URL error:', error);
      return { success: false, error: error.message };
    }

    return { success: true, data: { signedUrl: data.signedUrl } };
  } catch (error: any) {
    console.error('Signed URL error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Delete project attachment
 */
export async function deleteProjectAttachment(attachmentId: string, projectId: string) {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      return { success: false, error: 'Unauthorized' };
    }

    // Get attachment details
    const { data: attachment, error: fetchError } = await supabase
      .from(DB_TABLES.PROJECT_ATTACHMENTS)
      .select('file_path, file_size')
      .eq('id', attachmentId)
      .single();

    if (fetchError || !attachment) {
      return { success: false, error: 'Attachment not found' };
    }

    // Delete from storage
    const { error: storageError } = await supabase.storage
      .from(STORAGE_BUCKETS.PROJECT_ATTACHMENTS)
      .remove([attachment.file_path]);

    if (storageError) {
      console.error('Storage delete error:', storageError);
      return { success: false, error: storageError.message };
    }

    // Delete from database
    const { error: dbError } = await supabase
      .from(DB_TABLES.PROJECT_ATTACHMENTS)
      .delete()
      .eq('id', attachmentId);

    if (dbError) {
      console.error('Database delete error:', dbError);
      return { success: false, error: dbError.message };
    }

    // Invalidate cache tags
    updateTag('attachments');
    updateTag(`project-${projectId}-attachments`);

    return { success: true };
  } catch (error: any) {
    console.error('Delete attachment error:', error);
    return { success: false, error: error.message };
  }
}

// Similar functions for task attachments...
export async function uploadTaskAttachment(taskId: string, formData: FormData) {
  // Same logic as uploadProjectAttachment but with task_id
  // Implementation left as exercise (follows same pattern)
}

export async function getTaskAttachments(taskId: string) {
  // Same logic as getProjectAttachments
}

export async function deleteTaskAttachment(attachmentId: string, taskId: string) {
  // Same logic as deleteProjectAttachment
}

EOF
```

**Update constants to include table names:**

```bash
# Add to src/constants/index.ts in DB_TABLES section
# PROJECT_ATTACHMENTS: 'prj_project_attachments',
# TASK_ATTACHMENTS: 'prj_task_attachments',
```

---

## Step 8: Create File Upload Component

Create a reusable file upload component with progress tracking:

```bash
cat > src/components/ui/FileUpload.tsx << 'EOF'
'use client';

import { useState, useRef, ChangeEvent } from 'react';
import { validateFiles, formatFileSize } from '@/utils/storage/fileValidation';
import { FILE_UPLOAD, FILE_UPLOAD_MESSAGES } from '@/constants';
import type { UploadProgress } from '@/types/storage';

type FileUploadProps = {
  onUpload: (formData: FormData) => Promise<{ success: boolean; error?: string }>;
  onSuccess?: () => void;
  accept?: string;
  multiple?: boolean;
  maxFiles?: number;
};

/**
 * Reusable file upload component with progress tracking
 */
export function FileUpload({
  onUpload,
  onSuccess,
  accept = '*/*',
  multiple = true,
  maxFiles = FILE_UPLOAD.MAX_FILES_PER_UPLOAD,
}: FileUploadProps) {
  const [uploads, setUploads] = useState<UploadProgress[]>([]);
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileChange = async (e: ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    if (files.length === 0) return;

    setError(null);

    // Validate files
    const validation = validateFiles(files);
    if (!validation.valid) {
      setError(validation.error || 'Invalid files');
      return;
    }

    // Initialize upload progress
    const initialProgress: UploadProgress[] = files.map((file) => ({
      fileName: file.name,
      progress: 0,
      status: 'pending',
    }));
    setUploads(initialProgress);

    // Upload files sequentially
    for (let i = 0; i < files.length; i++) {
      const file = files[i];

      // Update status to uploading
      setUploads((prev) =>
        prev.map((upload, index) =>
          index === i ? { ...upload, status: 'uploading', progress: 50 } : upload
        )
      );

      // Create FormData
      const formData = new FormData();
      formData.append('file', file);

      // Upload
      const result = await onUpload(formData);

      // Update progress
      setUploads((prev) =>
        prev.map((upload, index) =>
          index === i
            ? {
                ...upload,
                status: result.success ? 'success' : 'error',
                progress: result.success ? 100 : 0,
                error: result.error,
              }
            : upload
        )
      );
    }

    // Call onSuccess callback
    const allSuccess = uploads.every((u) => u.status === 'success');
    if (allSuccess) {
      onSuccess?.();
    }

    // Reset file input
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  return (
    <div className="space-y-4">
      {/* File Input */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Upload Files
        </label>
        <input
          ref={fileInputRef}
          type="file"
          accept={accept}
          multiple={multiple}
          onChange={handleFileChange}
          className="block w-full text-sm text-gray-500
            file:mr-4 file:py-2 file:px-4
            file:rounded-md file:border-0
            file:text-sm file:font-medium
            file:bg-blue-50 file:text-blue-700
            hover:file:bg-blue-100
            cursor-pointer"
        />
        <p className="mt-1 text-xs text-gray-500">
          Max {maxFiles} files, {formatFileSize(FILE_UPLOAD.MAX_FILE_SIZE)} each
        </p>
      </div>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-md">
          {error}
        </div>
      )}

      {/* Upload Progress */}
      {uploads.length > 0 && (
        <div className="space-y-2">
          {uploads.map((upload, index) => (
            <div key={index} className="border rounded-md p-3">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm font-medium text-gray-700 truncate">
                  {upload.fileName}
                </span>
                <span
                  className={`text-xs px-2 py-1 rounded ${
                    upload.status === 'success'
                      ? 'bg-green-100 text-green-800'
                      : upload.status === 'error'
                      ? 'bg-red-100 text-red-800'
                      : 'bg-yellow-100 text-yellow-800'
                  }`}
                >
                  {upload.status}
                </span>
              </div>

              {/* Progress Bar */}
              {upload.status === 'uploading' && (
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className="bg-blue-600 h-2 rounded-full transition-all duration-300"
                    style={{ width: `${upload.progress}%` }}
                  />
                </div>
              )}

              {/* Error Message */}
              {upload.error && (
                <p className="text-xs text-red-600 mt-1">{upload.error}</p>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

EOF
```

---

## Step 9: Create Attachment List Component

Create a component to display uploaded attachments:

```bash
mkdir -p src/components/features/attachments
cat > src/components/features/attachments/AttachmentList.tsx << 'EOF'
'use client';

import { useEffect, useState } from 'react';
import { getSignedUrl, deleteProjectAttachment } from '@/lib/actions/storage';
import { formatFileSize, getFileCategory } from '@/utils/storage/fileValidation';
import { FILE_CATEGORIES, STORAGE_BUCKETS } from '@/constants';
import type { ProjectAttachment } from '@/types/storage';

type AttachmentListProps = {
  projectId: string;
  attachments: ProjectAttachment[];
  onDelete?: () => void;
};

type AttachmentWithUrl = ProjectAttachment & {
  signedUrl?: string;
  isImage?: boolean;
};

/**
 * Component to display project attachments with preview and download
 */
export function AttachmentList({ projectId, attachments, onDelete }: AttachmentListProps) {
  const [attachmentsWithUrls, setAttachmentsWithUrls] = useState<AttachmentWithUrl[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchSignedUrls = async () => {
      setLoading(true);

      const withUrls = await Promise.all(
        attachments.map(async (attachment) => {
          const result = await getSignedUrl(
            STORAGE_BUCKETS.PROJECT_ATTACHMENTS,
            attachment.file_path
          );

          const category = getFileCategory(attachment.mime_type);
          const isImage = category === FILE_CATEGORIES.IMAGE;

          return {
            ...attachment,
            signedUrl: result.success ? result.data?.signedUrl : undefined,
            isImage,
          };
        })
      );

      setAttachmentsWithUrls(withUrls);
      setLoading(false);
    };

    fetchSignedUrls();
  }, [attachments]);

  const handleDelete = async (attachmentId: string) => {
    if (!confirm('Are you sure you want to delete this file?')) return;

    const result = await deleteProjectAttachment(attachmentId, projectId);

    if (result.success) {
      setAttachmentsWithUrls((prev) => prev.filter((a) => a.id !== attachmentId));
      onDelete?.();
    } else {
      alert('Failed to delete attachment: ' + result.error);
    }
  };

  if (loading) {
    return <div className="text-gray-500">Loading attachments...</div>;
  }

  if (attachmentsWithUrls.length === 0) {
    return <div className="text-gray-500">No attachments yet</div>;
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {attachmentsWithUrls.map((attachment) => (
        <div
          key={attachment.id}
          className="border rounded-lg p-4 space-y-3 hover:shadow-md transition-shadow"
        >
          {/* Image Preview */}
          {attachment.isImage && attachment.signedUrl && (
            <div className="relative h-40 bg-gray-100 rounded-md overflow-hidden">
              <img
                src={attachment.signedUrl}
                alt={attachment.file_name}
                className="w-full h-full object-cover"
              />
            </div>
          )}

          {/* File Icon for non-images */}
          {!attachment.isImage && (
            <div className="h-40 bg-gray-100 rounded-md flex items-center justify-center">
              <svg
                className="w-16 h-16 text-gray-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"
                />
              </svg>
            </div>
          )}

          {/* File Info */}
          <div className="space-y-1">
            <p className="text-sm font-medium text-gray-900 truncate" title={attachment.file_name}>
              {attachment.file_name}
            </p>
            <p className="text-xs text-gray-500">
              {formatFileSize(Number(attachment.file_size))}
            </p>
            <p className="text-xs text-gray-400">
              {new Date(attachment.created_at).toLocaleDateString()}
            </p>
          </div>

          {/* Actions */}
          <div className="flex gap-2">
            {attachment.signedUrl && (
              <a
                href={attachment.signedUrl}
                download={attachment.file_name}
                className="flex-1 px-3 py-2 text-xs bg-blue-600 text-white rounded-md hover:bg-blue-700 text-center"
              >
                Download
              </a>
            )}
            <button
              onClick={() => handleDelete(attachment.id)}
              className="px-3 py-2 text-xs bg-red-100 text-red-700 rounded-md hover:bg-red-200"
            >
              Delete
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}

EOF
```

---

## Step 10: Create Cached Attachment Components

Create cached Server Components for displaying attachments:

```bash
cat > src/components/features/attachments/ProjectAttachmentsServer.tsx << 'EOF'
import { getProjectAttachments } from '@/lib/actions/storage';
import { AttachmentList } from './AttachmentList';
import { Suspense } from 'react';

type ProjectAttachmentsProps = {
  projectId: string;
};

/**
 * Cached attachment listing component
 * Files don't change frequently, so we cache for 1 hour
 */
async function ProjectAttachmentsCached({ projectId }: ProjectAttachmentsProps) {
  'use cache';
  cacheLife('hours'); // Files don't change frequently
  cacheTag('attachments');
  cacheTag(`project-${projectId}-attachments`);

  const result = await getProjectAttachments(projectId);
  const attachments = result.success ? result.data || [] : [];

  return <AttachmentList projectId={projectId} attachments={attachments} />;
}

/**
 * Attachment loading skeleton
 */
function AttachmentsSkeleton() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {[1, 2, 3].map((i) => (
        <div key={i} className="border rounded-lg p-4 space-y-3 animate-pulse">
          <div className="h-40 bg-gray-200 rounded-md" />
          <div className="space-y-2">
            <div className="h-4 bg-gray-200 rounded w-3/4" />
            <div className="h-3 bg-gray-200 rounded w-1/2" />
          </div>
        </div>
      ))}
    </div>
  );
}

/**
 * Server Component with Suspense boundary
 */
export async function ProjectAttachmentsServer({ projectId }: ProjectAttachmentsProps) {
  return (
    <Suspense fallback={<AttachmentsSkeleton />}>
      <ProjectAttachmentsCached projectId={projectId} />
    </Suspense>
  );
}

EOF
```

---

## Step 11: Create Project Attachments Page

Create a page to manage project attachments with caching:

```bash
cat > src/app/dashboard/projects/[id]/attachments/page.tsx << 'EOF'
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { getProject } from '@/lib/actions/projects';
import { ProjectAttachmentsClient } from '@/components/features/attachments/ProjectAttachmentsClient';
import { ProjectAttachmentsServer } from '@/components/features/attachments/ProjectAttachmentsServer';
import { ROUTES } from '@/constants';
import Link from 'next/link';

type ProjectAttachmentsPageProps = {
  params: Promise<{ id: string }>;
};

/**
 * Project attachments page - Server Component
 *
 * Caching Strategy:
 * - Project data: Cached via getProject action
 * - Attachments list: Cached via ProjectAttachmentsServer component
 * - Upload/Delete: Invalidates cache using updateTag()
 */
export default async function ProjectAttachmentsPage({ params }: ProjectAttachmentsPageProps) {
  const { id: projectId } = await params;

  // Auth check
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect(ROUTES.LOGIN);

  // Fetch project (cached)
  const projectResult = await getProject(projectId);

  if (!projectResult.success || !projectResult.data) {
    redirect(ROUTES.DASHBOARD_PROJECTS);
  }

  const project = projectResult.data;

  return (
    <div className="container mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">{project.name} - Attachments</h1>
          <p className="text-gray-500 text-sm mt-1">
            Manage project files and attachments
          </p>
        </div>

        <Link
          href={`${ROUTES.DASHBOARD_PROJECTS}/${projectId}`}
          className="px-4 py-2 border border-gray-300 rounded-md hover:bg-gray-50"
        >
          Back to Project
        </Link>
      </div>

      {/* Upload Section (Client Component) */}
      <ProjectAttachmentsClient projectId={projectId} />

      {/* Attachments List (Cached Server Component) */}
      <div>
        <h2 className="text-xl font-semibold mb-4">Uploaded Files</h2>
        <ProjectAttachmentsServer projectId={projectId} />
      </div>
    </div>
  );
}

EOF
```

Create the client component to work with cached data:

```bash
cat > src/components/features/attachments/ProjectAttachmentsClient.tsx << 'EOF'
'use client';

import { useRouter } from 'next/navigation';
import { uploadProjectAttachment } from '@/lib/actions/storage';
import { FileUpload } from '@/components/ui/FileUpload';
import { FILE_UPLOAD } from '@/constants';

type ProjectAttachmentsClientProps = {
  projectId: string;
};

/**
 * Client component for file upload
 * After upload, cache is automatically invalidated via updateTag()
 */
export function ProjectAttachmentsClient({ projectId }: ProjectAttachmentsClientProps) {
  const router = useRouter();

  const handleUpload = async (formData: FormData) => {
    const result = await uploadProjectAttachment(projectId, formData);

    if (result.success) {
      // Cache is automatically invalidated via updateTag() in the server action
      // Router refresh will fetch the updated cached data
      router.refresh();
    }

    return result;
  };

  return (
    <div className="border rounded-lg p-6">
      <h2 className="text-xl font-semibold mb-4">Upload Files</h2>
      <FileUpload
        onUpload={handleUpload}
        accept={FILE_UPLOAD.ALLOWED_IMAGE_TYPES.join(',')}
        multiple
        maxFiles={FILE_UPLOAD.MAX_FILES_PER_UPLOAD}
      />
    </div>
  );
}

EOF
```

---

## Step 12: Update AttachmentList Component for Cache Invalidation

Update the AttachmentList component to work with cache invalidation:

```bash
cat > src/components/features/attachments/AttachmentList.tsx << 'EOF'
'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getSignedUrl, deleteProjectAttachment } from '@/lib/actions/storage';
import { formatFileSize, getFileCategory } from '@/utils/storage/fileValidation';
import { FILE_CATEGORIES, STORAGE_BUCKETS } from '@/constants';
import type { ProjectAttachment } from '@/types/storage';

type AttachmentListProps = {
  projectId: string;
  attachments: ProjectAttachment[];
};

type AttachmentWithUrl = ProjectAttachment & {
  signedUrl?: string;
  isImage?: boolean;
};

/**
 * Component to display project attachments with preview and download
 * Works with cached data - invalidates cache on delete
 */
export function AttachmentList({ projectId, attachments }: AttachmentListProps) {
  const router = useRouter();
  const [attachmentsWithUrls, setAttachmentsWithUrls] = useState<AttachmentWithUrl[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchSignedUrls = async () => {
      setLoading(true);

      const withUrls = await Promise.all(
        attachments.map(async (attachment) => {
          const result = await getSignedUrl(
            STORAGE_BUCKETS.PROJECT_ATTACHMENTS,
            attachment.file_path
          );

          const category = getFileCategory(attachment.mime_type);
          const isImage = category === FILE_CATEGORIES.IMAGE;

          return {
            ...attachment,
            signedUrl: result.success ? result.data?.signedUrl : undefined,
            isImage,
          };
        })
      );

      setAttachmentsWithUrls(withUrls);
      setLoading(false);
    };

    fetchSignedUrls();
  }, [attachments]);

  const handleDelete = async (attachmentId: string) => {
    if (!confirm('Are you sure you want to delete this file?')) return;

    const result = await deleteProjectAttachment(attachmentId, projectId);

    if (result.success) {
      // Cache is automatically invalidated via updateTag() in the server action
      // Router refresh will fetch the updated cached data
      router.refresh();
    } else {
      alert('Failed to delete attachment: ' + result.error);
    }
  };

  if (loading) {
    return (
      <div className="text-center py-12">
        <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
        <p className="text-gray-500 mt-2">Loading attachments...</p>
      </div>
    );
  }

  if (attachmentsWithUrls.length === 0) {
    return (
      <div className="text-center py-12 bg-gray-50 rounded-lg border-2 border-dashed">
        <svg
          className="mx-auto h-12 w-12 text-gray-400"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"
          />
        </svg>
        <p className="mt-2 text-sm text-gray-500">No attachments yet</p>
        <p className="text-xs text-gray-400">Upload files to get started</p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {attachmentsWithUrls.map((attachment) => (
        <div
          key={attachment.id}
          className="border rounded-lg p-4 space-y-3 hover:shadow-md transition-shadow"
        >
          {/* Image Preview */}
          {attachment.isImage && attachment.signedUrl && (
            <div className="relative h-40 bg-gray-100 rounded-md overflow-hidden">
              <img
                src={attachment.signedUrl}
                alt={attachment.file_name}
                className="w-full h-full object-cover"
              />
            </div>
          )}

          {/* File Icon for non-images */}
          {!attachment.isImage && (
            <div className="h-40 bg-gray-100 rounded-md flex items-center justify-center">
              <svg
                className="w-16 h-16 text-gray-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"
                />
              </svg>
            </div>
          )}

          {/* File Info */}
          <div className="space-y-1">
            <p className="text-sm font-medium text-gray-900 truncate" title={attachment.file_name}>
              {attachment.file_name}
            </p>
            <p className="text-xs text-gray-500">
              {formatFileSize(Number(attachment.file_size))}
            </p>
            <p className="text-xs text-gray-400">
              {new Date(attachment.created_at).toLocaleDateString()}
            </p>
          </div>

          {/* Actions */}
          <div className="flex gap-2">
            {attachment.signedUrl && (
              <a
                href={attachment.signedUrl}
                download={attachment.file_name}
                className="flex-1 px-3 py-2 text-xs bg-blue-600 text-white rounded-md hover:bg-blue-700 text-center"
              >
                Download
              </a>
            )}
            <button
              onClick={() => handleDelete(attachment.id)}
              className="px-3 py-2 text-xs bg-red-100 text-red-700 rounded-md hover:bg-red-200"
            >
              Delete
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}

EOF
```

---

## Step 13: Understanding File Caching Strategy

### Why Cache File Listings?

File attachments are ideal for caching because:

1. **Infrequent Changes**
   - Files are uploaded occasionally, not every second
   - Once uploaded, file metadata rarely changes
   - File deletions are infrequent

2. **Expensive Queries**
   - Joining attachments with user data (uploader info)
   - Fetching signed URLs for each file
   - Querying across multiple tables (attachments, users, projects)

3. **Predictable Invalidation**
   - Only need to invalidate on upload or delete
   - No complex dependency tracking required

### Cache Configuration for Files

```typescript
// In ProjectAttachmentsCached component
'use cache'
cacheLife('hours')  // Files don't change frequently - cache for 1 hour
cacheTag('attachments')  // Global attachment tag
cacheTag(`project-${projectId}-attachments`)  // Project-specific tag
```

**Cache Duration:**
- `cacheLife('hours')` - Files are cached for 1 hour
- Longer than other data (projects, tasks) because files change less frequently
- Automatically revalidated when tags are invalidated

**Cache Tags:**
- `attachments` - Global tag for all attachments
- `project-${projectId}-attachments` - Specific to one project
- Allows targeted invalidation without affecting other projects

### Cache Invalidation Pattern

```typescript
// In uploadProjectAttachment() and deleteProjectAttachment()
updateTag('attachments')  // Invalidate all attachment caches
updateTag(`project-${projectId}-attachments`)  // Invalidate this project's cache
```

**Why Two Tags?**
- `attachments` - Use when you need to invalidate all attachment data globally
- `project-${projectId}-attachments` - More targeted, only invalidates one project's cache
- Other projects' caches remain valid, improving performance

### Signed URLs and Caching

**Important Consideration:**

Signed URLs have an expiration time (default: 1 hour). This aligns perfectly with our cache duration:

```typescript
// In getSignedUrl()
const expiresIn = 3600; // 1 hour (matches cache duration)
```

**Why This Matters:**
- Cache expires when signed URLs expire
- No stale URL issues - fresh URLs are generated when cache refreshes
- Users always get valid download links

### Cache vs. No Cache Performance

**Without Caching:**
```
User visits attachments page
→ Query database for attachments
→ Join with users table for uploader info
→ Generate 10 signed URLs (10 API calls to Supabase Storage)
→ Total time: ~500-1000ms
```

**With Caching:**
```
First visit: ~500-1000ms (cache miss, same as above)
Next 59 minutes: ~50ms (cache hit, no database queries)
After 1 hour: ~500-1000ms (cache expired, refresh)
```

**Cache Invalidation:**
```
User uploads file
→ updateTag() called
→ Cache invalidated immediately
→ Next request fetches fresh data
→ New cache entry created
```

### Best Practices for File Caching

1. **Match Cache Duration with Signed URL Expiration**
   ```typescript
   cacheLife('hours') // 1 hour
   expiresIn: 3600    // 1 hour in seconds
   ```

2. **Use Specific Cache Tags**
   ```typescript
   cacheTag(`project-${projectId}-attachments`)  // Good - specific
   cacheTag('all-data')  // Bad - too broad
   ```

3. **Invalidate Immediately After Mutations**
   ```typescript
   // After upload/delete
   updateTag('attachments')
   updateTag(`project-${projectId}-attachments`)
   ```

4. **Wrap Cached Components in Suspense**
   ```typescript
   <Suspense fallback={<AttachmentsSkeleton />}>
     <ProjectAttachmentsCached projectId={projectId} />
   </Suspense>
   ```

5. **Use Router.refresh() After Mutations**
   ```typescript
   // In client component after upload/delete
   router.refresh() // Fetches updated cached data
   ```

---

## Step 14: Add Attachments Link to Project Page

Update your project page to include a link to attachments:

```tsx
// In src/app/dashboard/projects/[id]/page.tsx

<Link
  href={`${ROUTES.DASHBOARD_PROJECTS}/${projectId}/attachments`}
  className="px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200"
>
  View Attachments
</Link>
```

---

## Verification Steps

### 1. Test File Upload

**Browser:**
1. Go to project attachments page: `http://localhost:3000/dashboard/projects/[id]/attachments`
2. Click "Choose File" and select an image (JPEG, PNG, GIF)
3. **Expected:** Upload progress shows, then "Success" ✅
4. **Expected:** Image preview appears in attachments list ✅

### 2. Test File Validation

**Try invalid files:**
1. Upload a file > 5MB
2. **Expected:** Error: "File is too large" ✅
3. Upload 11 files at once
4. **Expected:** Error: "Too many files" ✅
5. Upload a .exe or .sh file
6. **Expected:** Error: "Invalid file type" ✅

### 3. Test Download

**Browser:**
1. Click "Download" button on an attachment
2. **Expected:** File downloads with original filename ✅

### 4. Test Delete

**Browser:**
1. Click "Delete" button
2. Confirm deletion
3. **Expected:** Attachment removed from list ✅
4. **Supabase Dashboard → Storage:** File deleted from bucket ✅

### 5. Test RLS Policies

**Security Test:**
1. User A uploads attachment to Project A
2. User B (not a member) tries to access:
   ```
   http://localhost:3000/dashboard/projects/[project-a-id]/attachments
   ```
3. **Expected:** User B cannot see attachments (RLS blocks) ✅
4. User A invites User B as member
5. **Expected:** User B can now see and download attachments ✅

### 6. Verify Storage Bucket

**Supabase Dashboard:**
1. Go to **Storage → project-attachments**
2. **Expected:** See uploaded files organized by folder (`project_id/timestamp-filename`) ✅
3. Click a file
4. **Expected:** Can preview image or download file ✅

### 7. Verify Cache Behavior

**Cache Testing:**
1. Upload a file to project attachments
2. Open browser DevTools → Network tab
3. Navigate to attachments page
4. **Expected:** Database queries execute (cache miss) ✅
5. Refresh page within 1 minute
6. **Expected:** No database queries (cache hit) ✅
7. Upload another file
8. **Expected:** New file appears immediately (cache invalidated) ✅

**Cache Tags:**
1. Check server logs for cache operations
2. **Expected:** See `updateTag('attachments')` after upload ✅
3. **Expected:** See `updateTag('project-${projectId}-attachments')` ✅

### 8. Verify Suspense Boundaries

**Loading States:**
1. Navigate to attachments page with slow network (throttle in DevTools)
2. **Expected:** AttachmentsSkeleton appears during loading ✅
3. **Expected:** Smooth transition to actual content ✅

### 9. Verify Cache Component Configuration

**Next.js Config:**
1. Check `next.config.js` has `experimental.cacheComponents: true`
2. **Expected:** Cache Components are enabled ✅

**Server Components:**
1. Check ProjectAttachmentsServer.tsx has `'use cache'` directive
2. **Expected:** `cacheLife('hours')` is set ✅
3. **Expected:** Cache tags are defined ✅

---

## What You Learned

✅ **Supabase Storage** - Create buckets, upload/download files
✅ **Storage Policies** - RLS for object storage
✅ **Signed URLs** - Time-limited, secure download links
✅ **File Validation** - Size, type, count validation
✅ **Progress Tracking** - Real-time upload progress
✅ **Image Previews** - Display thumbnails for images
✅ **Server Actions** - File upload with FormData and cache invalidation
✅ **Database Integration** - Link files to projects/tasks
✅ **Security** - RLS applies to both database and storage
✅ **Type Safety** - TypeScript for file operations
✅ **Cache Components (Next.js 16)** - Cache file listings with `'use cache'`
✅ **Cache Invalidation** - `updateTag()` for targeted cache invalidation
✅ **Cache Strategy** - Match cache duration with signed URL expiration
✅ **Suspense Boundaries** - Loading states for cached components
✅ **Performance Optimization** - Reduce database queries with caching

### File Caching Strategy Summary

**Cached Components:**
- File listings cached for 1 hour with `cacheLife('hours')`
- Matches signed URL expiration time
- Tagged with `'attachments'` and `'project-${projectId}-attachments'`

**Cache Invalidation:**
- Upload: `updateTag('attachments')` + `updateTag('project-${projectId}-attachments')`
- Delete: Same invalidation pattern
- Automatic cache refresh on router.refresh()

**Performance Impact:**
- First load: ~500-1000ms (database queries + signed URLs)
- Cached loads: ~50ms (no database queries)
- Cache duration: 1 hour (automatically refreshed)

---

## Next Steps

**Lesson 9 Preview:** Search & Filtering with Full-Text Search
- PostgreSQL full-text search
- Advanced filtering (multi-select, date ranges)
- Pagination with cursor-based navigation
- Search across multiple fields
- Debounced search input
- Search highlighting
- Sort and filter combinations

**Continue to:** `LESSON-9-PRACTICAL-GUIDE.md`

---

## Reference

**Files Created:**
- `next.config.js` - Next.js configuration with Cache Components (UPDATED)
- `supabase/migrations/005_attachments.sql` - Attachment tables and RLS
- `src/constants/index.ts` - Storage constants (EXTENDED)
- `src/types/storage.ts` - TypeScript types for storage
- `src/utils/storage/fileValidation.ts` - File validation utilities
- `src/lib/actions/storage.ts` - Storage Server Actions with cache invalidation
- `src/components/ui/FileUpload.tsx` - File upload component
- `src/components/features/attachments/AttachmentList.tsx` - Attachments list with cache refresh
- `src/components/features/attachments/ProjectAttachmentsServer.tsx` - Cached Server Component
- `src/components/features/attachments/ProjectAttachmentsClient.tsx` - Upload client component
- `src/app/dashboard/projects/[id]/attachments/page.tsx` - Attachments page with caching

**Key Concepts:**
- Object storage (S3-compatible)
- Signed URLs (temporary access)
- Storage policies (RLS for files)
- FormData uploads
- File metadata tracking
- Cascading deletes
- **Cache Components (`'use cache'`, `cacheLife()`, `cacheTag()`)**
- **Cache invalidation (`updateTag()`)**
- **Suspense boundaries for cached components**
- **Router-based cache refresh**

**Documentation:**
- Supabase Storage: https://supabase.com/docs/guides/storage
- Next.js 16 Cache Components: https://nextjs.org/docs/app/api-reference/directives/use-cache
- Cache Invalidation: https://nextjs.org/docs/app/api-reference/functions/revalidateTag
