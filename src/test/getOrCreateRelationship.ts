import { UUID } from "crypto";
import { BgentRuntime, Relationship, getRelationship } from "../lib";

export async function getOrCreateRelationship({
  runtime,
  userA,
  userB,
}: {
  runtime: BgentRuntime;
  userA: UUID;
  userB: UUID;
}): Promise<Relationship> {
  // Check if a relationship already exists between userA and userB
  let relationship = await getRelationship({ runtime, userA, userB });

  if (!relationship) {
    try {
      // Check if a room already exists for the participants
      const rooms = await runtime.databaseAdapter.getRoomsByParticipants([
        userA,
        userB,
      ]);

      let roomId: UUID;

      if (!rooms || rooms.length === 0) {
        // If no room exists, create a new room for the relationship
        roomId = await runtime.databaseAdapter.createRoom("Direct Message");

        // Add participants to the newly created room
        await runtime.databaseAdapter.addParticipantToRoom(userA, roomId);
        await runtime.databaseAdapter.addParticipantToRoom(userB, roomId);
      } else {
        // If a room already exists, use the existing room
        roomId = rooms[0];
      }

      // Create the relationship
      await runtime.databaseAdapter.createRelationship({
        userA,
        userB,
      });

      // Fetch the newly created relationship
      relationship = await getRelationship({ runtime, userA, userB });

      if (!relationship) {
        throw new Error("Failed to fetch the created relationship");
      }
    } catch (error) {
      throw new Error(`Error creating relationship: ${JSON.stringify(error)}`);
    }
  }

  return relationship;
}
