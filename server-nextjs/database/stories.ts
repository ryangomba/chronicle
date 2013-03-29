import { BlockType, StoryBlock } from "../models";
import { getBlocks, getBlockWithID } from "./hydratedBlocks";

export async function getStoryWithID(storyID: string): Promise<StoryBlock> {
  const block = await getBlockWithID(storyID);
  if (block.type === BlockType.Story) {
    return block;
  }
  return null;
}

export async function getStoriesWithUserID(
  userID: string
): Promise<StoryBlock[]> {
  const stories: StoryBlock[] = [];
  const blocks = await getBlocks({ userID, type: BlockType.Story });
  blocks.forEach((block) => {
    if (block.type === BlockType.Story) {
      stories.push(block);
    }
  });
  return stories;
}
