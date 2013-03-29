import { DB } from "./firestore";
import { User } from "../models";

// HACK
async function _seedUser(): Promise<User> {
  const username = "janedoe";
  const usersRef = DB.collection("users");
  const users = await usersRef.where("username", "==", username).get();
  let user = users.docs[0];
  if (!user) {
    const userID = "user123";
    const document = usersRef.doc(userID);
    await document.set({
      id: userID,
      username,
      displayName: "Jane Doe",
    });
    user = await document.get();
  }
  return user.data() as User;
}

export async function getUser(usernameOrID: string): Promise<User> {
  // await _seedUser();

  const usersRef = DB.collection("users");
  const usersWithID = await usersRef.where("id", "==", usernameOrID).get();
  const usersWithUsername = await usersRef
    .where("username", "==", usernameOrID)
    .get();
  const users = [...usersWithID.docs, ...usersWithUsername.docs];
  return users.length > 0 ? (users[0].data() as User) : null;
}
