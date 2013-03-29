import firebase from "firebase";
import { DB } from "./firestore";
import { BlockType } from "../models";

export interface PersistedBlock {
  id: string;
  userID: string;
  type: BlockType;
  properties: {};
  content: string[]; // IDs of child blocks
}

export async function getPersistedBlockWithID(
  blockID: string
): Promise<PersistedBlock> {
  const blocksRef = DB.collection("blocks");
  const blockDoc = blocksRef.doc(blockID);
  const block = await blockDoc.get();
  return block.data() as PersistedBlock;
}

type PersistedBlockFilters = {
  ids?: string[];
  userID?: string;
  type?: BlockType;
};

export async function getPersistedBlocks(
  filters: PersistedBlockFilters
): Promise<PersistedBlock[]> {
  if (filters.ids) {
    return Promise.all(filters.ids.map((id) => getPersistedBlockWithID(id)));
  }

  const blocksRef = DB.collection("blocks");
  let blocksQuery: firebase.firestore.Query = blocksRef;
  if (filters.userID) {
    blocksQuery = blocksQuery.where("userID", "==", filters.userID);
  }
  if (filters.type) {
    blocksQuery = blocksQuery.where("type", "==", filters.type);
  }
  const blocksResult = await blocksQuery.get();
  return blocksResult.docs.map((d) => d.data()) as PersistedBlock[];
}

// Updating blocks

type InsertBlockParams = {
  id: string;
  userID: string;
  type: BlockType;
  properties: {};
  content: string[];
};

function validateInsertBlockParams(params: InsertBlockParams) {
  if (!params.id) {
    throw new Error("No ID for inserted block");
  }
  if (!params.userID) {
    throw new Error("No userID for inserted block");
  }
  if (!params.type) {
    throw new Error("No type for inserted block");
  }
  if (!params.properties) {
    throw new Error("No properties for inserted block");
  }
  if (!params.content) {
    throw new Error("No content for inserted block");
  }
}

async function insertBlock(params: InsertBlockParams): Promise<PersistedBlock> {
  validateInsertBlockParams(params);
  const blocksRef = DB.collection("blocks");
  const document = blocksRef.doc(params.id);
  await document.set(params);
  const block = await document.get();
  return block.data() as PersistedBlock;
}

async function insertBlocks(
  params: InsertBlockParams[]
): Promise<PersistedBlock[]> {
  return Promise.all(params.map((p) => insertBlock(p)));
}

type UpdateBlockParams = {
  id: string;
  type?: BlockType;
  properties?: {};
  content?: string[];
};

async function updateBlock(params: UpdateBlockParams): Promise<PersistedBlock> {
  const blocksRef = DB.collection("blocks");
  const document = blocksRef.doc(params.id);
  await document.update(params);
  const block = await document.get();
  return block.data() as PersistedBlock;
}

async function updateBlocks(
  params: UpdateBlockParams[]
): Promise<PersistedBlock[]> {
  return Promise.all(params.map((p) => updateBlock(p)));
}

type DeleteBlockParams = {
  id: string;
};

async function deleteBlock(params: DeleteBlockParams): Promise<boolean> {
  const blocksRef = DB.collection("blocks");
  const document = blocksRef.doc(params.id);
  await document.delete();
  return true;
}

async function deleteBlocks(params: DeleteBlockParams[]): Promise<boolean[]> {
  return Promise.all(params.map((p) => deleteBlock(p)));
}

type UpdateBlocksParams = {
  insert?: InsertBlockParams[];
  update?: UpdateBlockParams[];
  delete?: DeleteBlockParams[];
};

export async function editBlocks(
  params: UpdateBlocksParams
): Promise<PersistedBlock[]> {
  const insertedBlocks = await insertBlocks(params.insert || []);
  const updatedBlocks = await updateBlocks(params.update || []);
  await deleteBlocks(params.delete || []);
  return [...insertedBlocks, ...updatedBlocks];
}
