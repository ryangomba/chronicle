import { NextApiRequest, NextApiResponse } from "next";
import { BlockType, SomeBlock } from "../../../../../models";
import { getBlocks } from "../../../../../database/hydratedBlocks";
import {
  editBlocks,
  getPersistedBlocks,
  PersistedBlock,
} from "../../../../../database/persistedBlocks";

type Data = {
  blocks: PersistedBlock[] | SomeBlock[];
};

export default async function (
  req: NextApiRequest,
  res: NextApiResponse<Data>
) {
  switch (req.method) {
    case "GET":
      return await get(req, res);
    case "POST":
      return await post(req, res);
  }
}

async function get(req: NextApiRequest, res: NextApiResponse<Data>) {
  const userID = req.query.userID as string;
  const type = req.query.type as BlockType;
  const hydrate = req.query.hydrate === "true";
  const blocks = hydrate
    ? await getBlocks({ userID, type })
    : await getPersistedBlocks({ userID, type });
  res.statusCode = 200;
  res.json({
    blocks,
  });
}

async function post(req: NextApiRequest, res: NextApiResponse<Data>) {
  const userID = req.query.userID as string;
  const params = req.body;
  const blocks = await editBlocks(params);
  res.statusCode = 200;
  res.json({
    blocks,
  });
}
