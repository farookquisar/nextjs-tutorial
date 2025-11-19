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

## Step 1: Create Database Migration for Attachments

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

## Step 2: Create Storage Buckets in Supabase Dashboard

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

## Step 3: Extend Constants

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

## Step 4: Create Storage Types

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

## Step 5: Create File Upload Utilities

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

## Step 6: Create Storage Server Actions

Create Server Actions for file operations:

```bash
cat > src/lib/actions/storage.ts << 'EOF'
'use server';

import { createClient } from '@/lib/supabase/server';
import { revalidatePath } from 'next/cache';
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

    revalidatePath(`${ROUTES.DASHBOARD_PROJECTS}/${projectId}`);

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
      .select('file_path')
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

    revalidatePath(`${ROUTES.DASHBOARD_PROJECTS}/${projectId}`);

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

## Step 7: Create File Upload Component

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

## Step 8: Create Attachment List Component

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

## Step 9: Create Project Attachments Page

Create a page to manage project attachments:

```bash
cat > src/app/dashboard/projects/[id]/attachments/page.tsx << 'EOF'
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { getProject } from '@/lib/actions/projects';
import { getProjectAttachments } from '@/lib/actions/storage';
import { ProjectAttachmentsClient } from '@/components/features/attachments/ProjectAttachmentsClient';
import { ROUTES } from '@/constants';
import Link from 'next/link';

type ProjectAttachmentsPageProps = {
  params: Promise<{ id: string }>;
};

/**
 * Project attachments page - Server Component
 */
export default async function ProjectAttachmentsPage({ params }: ProjectAttachmentsPageProps) {
  const { id: projectId } = await params;

  // Auth check
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect(ROUTES.LOGIN);

  // Fetch project and attachments
  const [projectResult, attachmentsResult] = await Promise.all([
    getProject(projectId),
    getProjectAttachments(projectId),
  ]);

  if (!projectResult.success || !projectResult.data) {
    redirect(ROUTES.DASHBOARD_PROJECTS);
  }

  const project = projectResult.data;
  const attachments = attachmentsResult.success ? attachmentsResult.data || [] : [];

  return (
    <div className="container mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">{project.name} - Attachments</h1>
          <p className="text-gray-600">{attachments.length} files uploaded</p>
        </div>

        <Link
          href={`${ROUTES.DASHBOARD_PROJECTS}/${projectId}`}
          className="px-4 py-2 border border-gray-300 rounded-md hover:bg-gray-50"
        >
          Back to Project
        </Link>
      </div>

      {/* Client Component with Upload and List */}
      <ProjectAttachmentsClient projectId={projectId} initialAttachments={attachments} />
    </div>
  );
}

EOF
```

Create the client component:

```bash
cat > src/components/features/attachments/ProjectAttachmentsClient.tsx << 'EOF'
'use client';

import { useState } from 'react';
import { uploadProjectAttachment } from '@/lib/actions/storage';
import { FileUpload } from '@/components/ui/FileUpload';
import { AttachmentList } from './AttachmentList';
import { FILE_UPLOAD } from '@/constants';
import type { ProjectAttachment } from '@/types/storage';

type ProjectAttachmentsClientProps = {
  projectId: string;
  initialAttachments: ProjectAttachment[];
};

export function ProjectAttachmentsClient({
  projectId,
  initialAttachments,
}: ProjectAttachmentsClientProps) {
  const [attachments, setAttachments] = useState(initialAttachments);

  const handleUpload = async (formData: FormData) => {
    const result = await uploadProjectAttachment(projectId, formData);

    if (result.success && result.data) {
      setAttachments((prev) => [result.data as ProjectAttachment, ...prev]);
    }

    return result;
  };

  const handleDelete = () => {
    // Refresh attachments list from server
    window.location.reload();
  };

  return (
    <div className="space-y-8">
      {/* Upload Section */}
      <div className="border rounded-lg p-6">
        <h2 className="text-xl font-semibold mb-4">Upload Files</h2>
        <FileUpload
          onUpload={handleUpload}
          accept={FILE_UPLOAD.ALLOWED_IMAGE_TYPES.join(',')}
          multiple
          maxFiles={FILE_UPLOAD.MAX_FILES_PER_UPLOAD}
        />
      </div>

      {/* Attachments List */}
      <div>
        <h2 className="text-xl font-semibold mb-4">Uploaded Files</h2>
        <AttachmentList
          projectId={projectId}
          attachments={attachments}
          onDelete={handleDelete}
        />
      </div>
    </div>
  );
}

EOF
```

---

## Step 10: Add Attachments Link to Project Page

Update your project page to include a link to attachments:

```tsx
// In src/app/dashboard/projects/[id]/page.tsx

<Link
  href={`${ROUTES.DASHBOARD_PROJECTS}/${projectId}/attachments`}
  className="px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200"
>
  View Attachments ({attachmentCount})
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

---

## What You Learned

✅ **Supabase Storage** - Create buckets, upload/download files
✅ **Storage Policies** - RLS for object storage
✅ **Signed URLs** - Time-limited, secure download links
✅ **File Validation** - Size, type, count validation
✅ **Progress Tracking** - Real-time upload progress
✅ **Image Previews** - Display thumbnails for images
✅ **Server Actions** - File upload with FormData
✅ **Database Integration** - Link files to projects/tasks
✅ **Security** - RLS applies to both database and storage
✅ **Type Safety** - TypeScript for file operations

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
- `supabase/migrations/005_attachments.sql` - Attachment tables and RLS
- `src/constants/index.ts` - Storage constants (EXTENDED)
- `src/types/storage.ts` - TypeScript types for storage
- `src/utils/storage/fileValidation.ts` - File validation utilities
- `src/lib/actions/storage.ts` - Storage Server Actions
- `src/components/ui/FileUpload.tsx` - File upload component
- `src/components/features/attachments/AttachmentList.tsx` - Attachments list
- `src/components/features/attachments/ProjectAttachmentsClient.tsx` - Client component
- `src/app/dashboard/projects/[id]/attachments/page.tsx` - Attachments page

**Key Concepts:**
- Object storage (S3-compatible)
- Signed URLs (temporary access)
- Storage policies (RLS for files)
- FormData uploads
- File metadata tracking
- Cascading deletes

**Supabase Storage Docs:** https://supabase.com/docs/guides/storage
