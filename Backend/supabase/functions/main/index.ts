import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const { data, error } = await supabase.from("users").select("*").limit(1);

    if (error) throw error;

    return new Response(
      JSON.stringify({
        message: "Database is connected and Backend is running",
        user: data.length > 0 ? data[0] : "No users found",
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({
        message: "Failed to connect database but backend is running",
        error: err.message,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  }
});