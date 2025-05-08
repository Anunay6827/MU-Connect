import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const { admin_id, group_id, email_to_add } = await req.json();

    if (!admin_id || !group_id || !email_to_add) {
      return new Response(
        JSON.stringify({
          message: "admin_id, group_id, and email_to_add are required",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data: adminRecords, error: adminError } = await supabase
      .from("group_members")
      .select("is_admin")
      .eq("group_id", group_id)
      .eq("member_id", admin_id)
      .limit(1);

    if (
      adminError ||
      !adminRecords ||
      adminRecords.length === 0 ||
      !adminRecords[0].is_admin
    ) {
      return new Response(
        JSON.stringify({
          message: "Only an admin can add members to the group",
        }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data: userRecords, error: userError } = await supabase
      .from("users")
      .select("id")
      .eq("email", email_to_add)
      .limit(1);

    if (userError || !userRecords || userRecords.length === 0) {
      return new Response(
        JSON.stringify({
          message: "No user found with the provided email",
        }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    const user_id_to_add = userRecords[0].id;

    const { data, error } = await supabase
      .from("group_members")
      .insert([
        {
          group_id,
          member_id: user_id_to_add,
        },
      ])
      .select("*");

    if (error) throw error;

    return new Response(
      JSON.stringify({
        message: "User added to group successfully",
        membership: data,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";

    return new Response(
      JSON.stringify({
        message: "Failed to add user to group",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});