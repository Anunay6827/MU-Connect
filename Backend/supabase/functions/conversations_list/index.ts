import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

type ChatMessage = {
  id: number;
  created_at: string;
  sender_id: number;
  receiver_id: number;
  content: string;
  content_type: number;
};

type User = {
  id: number;
  name: string | null;
  profile_picture: string | null;
};

type ContactProfile = {
  id: number;
  name: string | null;
  profile_picture: string | null;
  last_message: ChatMessage;
};

type GroupMessage = {
  id: number;
  created_at: string;
  content: string;
  content_type: number;
  sender: number;
  group_id: number;
};

type Group = {
  id: number;
  name: string;
  last_message: GroupMessage | null;
};

Deno.serve(async (req) => {
  try {
    const { user_id } = await req.json();

    if (!user_id) {
      return new Response(JSON.stringify({ message: "user_id is required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // ---- ONE-ON-ONE CHATS ----
    const { data: chatMessages, error: chatError } = await supabase
      .from("chats_messages")
      .select("*")
      .or(`sender_id.eq.${user_id},receiver_id.eq.${user_id}`)
      .order("created_at", { ascending: false });

    if (chatError) throw chatError;

    const contactMap = new Map<number, ChatMessage>();

    for (const msg of chatMessages as ChatMessage[]) {
      const otherUserId =
        msg.sender_id === user_id ? msg.receiver_id : msg.sender_id;
      if (!contactMap.has(otherUserId)) {
        contactMap.set(otherUserId, msg); // save the first (latest) message
      }
    }

    const contactIds = Array.from(contactMap.keys());

    let contactProfiles: ContactProfile[] = [];
    if (contactIds.length > 0) {
      const { data: users, error: usersError } = await supabase
        .from("users")
        .select("id, name, profile_picture")
        .in("id", contactIds);

      if (usersError) throw usersError;

      contactProfiles = (users as User[]).map((user) => ({
        ...user,
        last_message: contactMap.get(user.id)!,
      }));
    }

    // ---- GROUP CHATS ----
    const { data: groupMemberships, error: memberError } = await supabase
      .from("group_members")
      .select("group_id")
      .eq("member_id", user_id);

    if (memberError) throw memberError;

    const groupIds = groupMemberships.map((gm) => gm.group_id);

    let groupConversations: Group[] = [];
    if (groupIds.length > 0) {
      const { data: groups, error: groupError } = await supabase
        .from("groups")
        .select("id, name, picture")
        .in("id", groupIds);

      if (groupError) throw groupError;

      for (const group of groups as { id: number; name: string }[]) {
        const { data: messages, error: msgError } = await supabase
          .from("groups_messages")
          .select("*")
          .eq("group_id", group.id)
          .order("created_at", { ascending: false })
          .limit(1);

        if (msgError) throw msgError;

        groupConversations.push({
          ...group,
          last_message: (messages as GroupMessage[])[0] || null,
        });
      }
    }

    const unifiedConversations = [
      ...contactProfiles.map((contact) => ({
        id: contact.id,
        name: contact.name,
        picture: contact.profile_picture,
        last_message_content:
          contact.last_message.content_type === 1
            ? "Media message"
            : contact.last_message.content,
        last_message_time: contact.last_message.created_at,
        conv_type: 0,
      })),
      ...groupConversations.map((group) => ({
        id: group.id,
        name: group.name,
        picture: (group as any).picture ?? null,
        last_message_content:
          group.last_message?.content_type === 1
            ? "Media message"
            : group.last_message?.content ?? "",
        last_message_time: group.last_message?.created_at ?? null,
        conv_type: 1,
      })),
    ];
    
    unifiedConversations.sort((a, b) => {
      const aTime = a.last_message_time ? new Date(a.last_message_time).getTime() : 0;
      const bTime = b.last_message_time ? new Date(b.last_message_time).getTime() : 0;
      return bTime - aTime;
    });    
    
    return new Response(
      JSON.stringify({
        message: "Conversations fetched successfully",
        conversations: unifiedConversations,
      }),
      { headers: { "Content-Type": "application/json" } }
    );    
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";

    return new Response(
      JSON.stringify({
        message: "Failed to fetch conversations",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});