import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const { email, name, password } = await req.json();

    if (!email || !name || !password) {
      return new Response(
        JSON.stringify({ message: "Email, name, and password are required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const allowedDomain = "mahindrauniversity.edu.in";
    const emailDomain = email.split("@")[1]?.toLowerCase().trim();

    if (emailDomain !== allowedDomain) {
      return new Response(
        JSON.stringify({
          message: "Only Mahindra University emails are allowed",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data: existingUser } = await supabase
      .from("users")
      .select("id")
      .eq("email", email)
      .single();

    if (existingUser) {
      return new Response(
        JSON.stringify({ message: "User with this email already exists" }),
        { status: 409, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data, error } = await supabase
      .from("users")
      .insert([{ email, name, password }])
      .select("*")
      .single();

    if (error) {
      return new Response(
        JSON.stringify({
          message: "Failed to register user",
          error: error.message,
        }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ message: "User registered successfully", user: data }),
      { status: 201, headers: { "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";

    return new Response(
      JSON.stringify({ message: "Internal Server Error", error: errorMessage }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
