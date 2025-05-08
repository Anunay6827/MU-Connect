import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

export async function createNotification(content: string, receiver: number) {
  if (!receiver || content === undefined) {
    throw new Error("Receiver and content are required");
  }

  const { data, error } = await supabase
    .from("notifications")
    .insert([{ content, receiver }])
    .select("*");

  if (error) {
    throw error;
  }

  return data;
}
