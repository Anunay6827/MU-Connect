import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

const ALLOWED_TYPES = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
  "image/heic",
  "image/heif",
  "image/bmp",
  "image/tiff",
  "image/svg+xml",
  "application/pdf"
];
const MAX_SIZE = 10 * 1024 * 1024;

export async function uploadImage(file: File): Promise<string | null> {
  if (!file) {
    console.error("No file provided.");
    return null;
  }

  if (!ALLOWED_TYPES.includes(file.type)) {
    console.error(
      `Unsupported file type: ${
        file.type
      }. Allowed types are: ${ALLOWED_TYPES.join(", ")}`
    );
    return null;
  }

  if (file.size > MAX_SIZE) {
    console.error(
      `File size exceeds the limit. Size: ${file.size} bytes, Max size: ${MAX_SIZE} bytes`
    );
    return null;
  }

  const fileName = `${Date.now()}_${file.name}`;

  try {
    const { error } = await supabase.storage
      .from("media")
      .upload(fileName, file.stream(), {
        cacheControl: "3600",
        upsert: true,
      });

    if (error) {
      console.error(`Error uploading file: ${error.message}`);
      return null;
    }

    const { data } = supabase.storage
      .from("media")
      .getPublicUrl(fileName);

    return data?.publicUrl ?? null;
  } catch (err) {
    console.error("Unexpected error during file upload:", err);
    return null;
  }
}
