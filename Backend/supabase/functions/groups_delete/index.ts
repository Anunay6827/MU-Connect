import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const { user_id, group_id } = await req.json();

    if (!user_id || !group_id) {
      return new Response(
        JSON.stringify({
          message: "User ID and Group ID are required",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data: groupMemberData, error: groupMemberError } = await supabase
      .from("group_members")
      .select("is_admin")
      .eq("group_id", group_id)
      .eq("member_id", user_id)
      .single();

    if (groupMemberError) {
      throw groupMemberError;
    }

    if (!groupMemberData || !groupMemberData.is_admin) {
      return new Response(
        JSON.stringify({
          message: "Only the admin can delete the group",
        }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      );
    }

    const { error: deleteMessagesError } = await supabase
      .from("groups_messages")
      .delete()
      .eq("group_id", group_id);

    if (deleteMessagesError) {
      throw deleteMessagesError;
    }

    const { error: deleteMembersError } = await supabase
      .from("group_members")
      .delete()
      .eq("group_id", group_id);

    if (deleteMembersError) {
      throw deleteMembersError;
    }

    const { error: deleteGroupError } = await supabase
      .from("groups")
      .delete()
      .eq("id", group_id);

    if (deleteGroupError) {
      throw deleteGroupError;
    }

    return new Response(
      JSON.stringify({
        message: "Group and its members, messages deleted successfully",
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";

    return new Response(
      JSON.stringify({
        message: "Failed to delete the group",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});