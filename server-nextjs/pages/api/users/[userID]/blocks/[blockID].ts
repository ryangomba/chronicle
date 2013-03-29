import { NextApiRequest, NextApiResponse } from "next";
import { SomeBlock } from "../../../../../models";
import { getBlockWithID } from "../../../../../database/hydratedBlocks";

type Data = {
  block: SomeBlock;
};

export default async function (
  req: NextApiRequest,
  res: NextApiResponse<Data>
) {
  const blockID = req.query.blockID as string;
  const block = await getBlockWithID(blockID);
  if (!block) {
    res.statusCode = 404;
    res.json({ block: null });
    return;
  }
  res.statusCode = 200;
  res.json({
    block,
  });
}
