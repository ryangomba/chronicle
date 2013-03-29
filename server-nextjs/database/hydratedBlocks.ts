import {
  getPersistedBlockWithID,
  getPersistedBlocks,
  PersistedBlock,
} from "./persistedBlocks";
import { BlockType, SomeBlock } from "../models";

async function getBlockForPersistedBlock(
  block: PersistedBlock
): Promise<SomeBlock> {
  const children = await getPersistedBlocks({ ids: block.content });
  children.sort(
    (c1, c2) => block.content.indexOf(c1.id) - block.content.indexOf(c2.id)
  );
  const content = await Promise.all(
    children.map((child) => getBlockForPersistedBlock(child))
  );
  return {
    ...block,
    content,
  } as SomeBlock;
}

export async function getBlockWithID(blockID: string): Promise<SomeBlock> {
  const persistedBlock = await getPersistedBlockWithID(blockID);
  return await getBlockForPersistedBlock(persistedBlock);
}

type BlockFilters = {
  userID?: string;
  type?: BlockType;
};

export async function getBlocks(filters: BlockFilters): Promise<SomeBlock[]> {
  const persistedBlocks = await getPersistedBlocks(filters);
  return Promise.all(
    persistedBlocks.map((block) => getBlockForPersistedBlock(block))
  );
}
