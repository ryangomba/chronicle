import { NextApiRequest, NextApiResponse } from "next";
import { User } from "../../../../models";
import { getUser } from "../../../../database/users";

type Data = {
  user: User;
};

export default async function (
  req: NextApiRequest,
  res: NextApiResponse<Data>
) {
  const userID = req.query.userID as string;
  const user = await getUser(userID);
  if (!user) {
    res.statusCode = 404;
    res.json({ user: null });
    return;
  }
  res.statusCode = 200;
  res.json({
    user,
  });
}
