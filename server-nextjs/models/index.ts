export type User = {
  id: string;
  createdAt: Date;
  username: string;
  displayName: string;
};

export enum BlockType {
  Story = "STORY",
  Text = "TEXT",
  Photo = "PHOTO",
}

export interface Block {
  id: string;
  userID: string;
  type: BlockType;
  properties: {};
  content: SomeBlock[];
}

export interface StoryBlock extends Block {
  type: BlockType.Story;
  properties: {
    title: string;
  };
}

export interface TextBlock extends Block {
  type: BlockType.Text;
  properties: {
    title: string;
  };
}

export interface PhotoBlock extends Block {
  type: BlockType.Photo;
  properties: {
    source: string;
  };
}

export type SomeBlock = StoryBlock | PhotoBlock | TextBlock;
