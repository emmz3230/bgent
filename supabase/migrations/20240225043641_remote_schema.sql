create table "public"."credits" (
    "id" bigint generated by default as identity not null,
    "created_at" timestamp with time zone not null default now(),
    "sender_id" text,
    "receiver_id" text,
    "amount" numeric,
    "reason" text
);


alter table "public"."credits" enable row level security;

alter table "public"."accounts" alter column "id" drop default;

alter table "public"."accounts" enable row level security;

alter table "public"."descriptions" enable row level security;

alter table "public"."goals" enable row level security;

alter table "public"."lore" enable row level security;

alter table "public"."messages" enable row level security;

alter table "public"."participants" enable row level security;

alter table "public"."relationships" enable row level security;

alter table "public"."rooms" enable row level security;

alter table "public"."summarizations" enable row level security;

CREATE UNIQUE INDEX credits_pkey ON public.credits USING btree (id);

alter table "public"."credits" add constraint "credits_pkey" PRIMARY KEY using index "credits_pkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.check_similarity_and_insert(query_table_name text, query_user_id uuid, query_user_ids uuid[], query_content jsonb, query_room_id uuid, query_embedding vector, similarity_threshold double precision)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    similar_found BOOLEAN := FALSE;
    select_query TEXT;
    insert_query TEXT;
BEGIN
    -- Only perform the similarity check if query_embedding is not NULL
    IF query_embedding IS NOT NULL THEN
        -- Build a dynamic query to check for existing similar embeddings using cosine distance
        select_query := format(
        'SELECT EXISTS (' ||
            'SELECT 1 ' ||
            'FROM %I ' ||
            'WHERE user_id = %L ' ||
            'AND user_ids @> %L ' ||  -- Assuming this is correct
            'AND user_ids <@ %L ' ||  -- Assuming this needs to be included again
            'AND embedding <=> %L < %L ' ||
            'LIMIT 1' ||
        ')',
        query_table_name,
        query_user_id,
        query_user_ids,  -- First usage
        query_user_ids,  -- Second usage (added)
        query_embedding,
        similarity_threshold
    );


        -- Execute the query to check for similarity
        EXECUTE select_query INTO similar_found;
    END IF;

    -- Prepare the insert query with 'unique' field set based on the presence of similar records or NULL query_embedding
    insert_query := format(
        'INSERT INTO %I (user_id, user_ids, content, room_id, embedding, "unique") ' ||
        'VALUES (%L, %L, %L, %L, %L, %L)',
        query_table_name,
        query_user_id,
        query_user_ids,
        query_content,
        query_room_id,
        query_embedding,
        NOT similar_found OR query_embedding IS NULL  -- Set 'unique' to true if no similar record is found or query_embedding is NULL
    );

    -- Execute the insert query
    EXECUTE insert_query;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_friendship_with_host_agent()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  host_agent_id UUID := '00000000-0000-0000-0000-000000000000';
  new_room_id UUID;
BEGIN
  -- Assuming NEW.id is the user ID of the newly inserted/updated row triggering this action
  -- Create a new room for the direct message between the new user and the host agent
  INSERT INTO rooms (created_by, name, is_dm)
  VALUES (NEW.id, 'Direct Message with Host Agent', TRUE)
  RETURNING id INTO new_room_id;

  -- Create a new friendship between the new user and the host agent
  INSERT INTO relationships (user_a, user_b, status, room_id)
  VALUES (NEW.id, host_agent_id, 'FRIENDS', new_room_id);

  -- Add both users as participants of the new room
  INSERT INTO participants (user_id, room_id)
  VALUES (NEW.id, new_room_id), (host_agent_id, new_room_id);

  RETURN NEW; -- For AFTER triggers, or NULL for BEFORE triggers
END;
$function$
;

grant delete on table "public"."credits" to "anon";

grant insert on table "public"."credits" to "anon";

grant references on table "public"."credits" to "anon";

grant select on table "public"."credits" to "anon";

grant trigger on table "public"."credits" to "anon";

grant truncate on table "public"."credits" to "anon";

grant update on table "public"."credits" to "anon";

grant delete on table "public"."credits" to "authenticated";

grant insert on table "public"."credits" to "authenticated";

grant references on table "public"."credits" to "authenticated";

grant select on table "public"."credits" to "authenticated";

grant trigger on table "public"."credits" to "authenticated";

grant truncate on table "public"."credits" to "authenticated";

grant update on table "public"."credits" to "authenticated";

grant delete on table "public"."credits" to "service_role";

grant insert on table "public"."credits" to "service_role";

grant references on table "public"."credits" to "service_role";

grant select on table "public"."credits" to "service_role";

grant trigger on table "public"."credits" to "service_role";

grant truncate on table "public"."credits" to "service_role";

grant update on table "public"."credits" to "service_role";

create policy "Enable insert for authenticated users only"
on "public"."lore"
as permissive
for all
to authenticated
using (true)
with check (true);


create policy "Enable read access for all users"
on "public"."lore"
as permissive
for select
to authenticated
using (true);



