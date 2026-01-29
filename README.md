# File History App

A Flutter take‑home assignment that implements a **local file history** for processed documents, using [`simplest_document_scanner`](https://pub.dev/packages/simplest_document_scanner).

The app lets users:

- Scan documents via camera (using `simplest_document_scanner`)
- Import existing PDF files from storage
- Maintain a **history** of all processed files
- Mark/unmark **favorites**
- **Search** by file name
- **Delete** entries from history (without deleting the real files)
- View file **details + extracted text**:
  - PDFs → text from PDF (and OCR fallback)
  - Images → OCR text from image

Everything is stored locally (no backend/API).

---

## Screenshots

> Add real screenshots later, e.g.:

- History list (all files)
- Starred files list
- File details with extracted text (image + PDF)

---

## Features

### 1. File History

- Shows all processed files created via:
  - Camera scan (`simplest_document_scanner`)
  - Imported PDF (via `file_picker`)
- Each entry shows:
  - File name
  - Size
  - Date added (first seen)
  - Type (`PDF`, `Image`, `Other`)
  - A visual indicator if the file **no longer exists** on disk
- Serial number for each row in the list

### 2. Favorites (Starred Files)

- Star/unstar any file from the list or detail page.
- AppBar star icon opens a dedicated **Starred Files** page.
- The starred page shows only favorite items, with their own serial numbers.

### 3. Search

- Search field at the top of the history screen.
- Filters the in‑memory list by filename (case‑insensitive).
- Does not hit storage repeatedly; filter is computed in `FileHistoryState.filteredFiles`.

### 4. Delete from History

- Delete icon on each item.
- Removes only the **history record** from Hive, not the actual file on disk.
- If the file is missing on disk, it still appears in history (with “Missing” marker) until the user deletes the record.

### 5. File Details

On tap of any item, the app navigates to **FileDetailPage**, which shows:

- Name
- Full path
- Type
- Size
- Created at (first seen)
- Last opened
- Exists on disk (Yes / No)
- Favorite (Yes / No)

Plus:

#### For image files

- **Image preview** card (rounded corners)
- **Extracted text** card:
  - Text recognized using **Google ML Kit Text Recognition**
  - Text shown in a bordered, rounded container
  - A **copy icon** to copy all extracted text to clipboard  
    (shows “Text copied to clipboard” via `SnackBar`)

#### For PDF files

- **Extracted text** card:
  - First tries to read the **text layer** using `syncfusion_flutter_pdf`
  - If that’s empty (scanned PDF with only images):
    - Searches for images like `scan_<timestamp>_page_<n>.jpg` in the same folder
    - Runs ML Kit OCR against those images
    - Concatenates their text
  - Same bordered container + copy icon as image files

If no text is detected (or OCR/text extraction fails gracefully), the UI shows:

> “No text detected or file contains no text.”

---

## Architecture

**Style:** Feature‑first with layered architecture + BLoC.

### Layers

- **Domain**
  - `ProcessedFile` entity
  - `FileHistoryRepository` interface
- **Data**
  - `FileHistoryLocalDataSource` (Hive box wrapper)
  - `FileHistoryRepositoryImpl` (implements `FileHistoryRepository`)
- **Presentation**
  - `FileHistoryBloc` + events + state
  - Pages:
    - `FileHistoryPage` (all items)
    - `StarredFilesPage` (favorites)
    - `FileDetailPage` (details + extracted text)
  - Widgets:
    - `FileListItem` (single row in the list, with serial number)

### State management

- [`flutter_bloc`](https://pub.dev/packages/flutter_bloc)
- `FileHistoryBloc` is created at the top in `main.dart` and injected using `BlocProvider`.

### Storage

- [`hive` + `hive_flutter`](https://pub.dev/packages/hive_flutter)
- A single box `file_history` stores metadata per file, keyed by file **path**.

This ensures:

- **No duplicates**: path is unique key → upsert instead of insert.
- We can easily check if the underlying file exists using `File(path).existsSync()`.

---

## Folder Structure

```text
lib/
  main.dart
  core/
    theme/
      app_theme.dart
    utils/
      format_utils.dart
  features/
    file_history/
      domain/
        entities/
          processed_file.dart
        repositories/
          file_history_repository.dart
      data/
        datasources/
          file_history_local_data_source.dart
        repositories/
          file_history_repository_impl.dart
        text_extractor.dart
      presentation/
        bloc/
          file_history_bloc.dart
          file_history_event.dart
          file_history_state.dart
        pages/
          file_history_page.dart
          starred_files_page.dart
          file_detail_page.dart
        widgets/
          file_list_item.dart