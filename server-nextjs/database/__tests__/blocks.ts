import { v4 as uuid } from "uuid";
import { BlockType } from "../../models";
import { editBlocks } from "../persistedBlocks";
import { getStoryWithID } from "../stories";

it("edits some blocks", async () => {
  const photoBlockID = uuid();
  const storyBlockID = uuid();
  const textBlockID = uuid();

  // Create a story block with a photo.
  {
    const blocks = await editBlocks({
      insert: [
        {
          id: photoBlockID,
          userID: "abc",
          type: BlockType.Photo,
          properties: {
            source: "http://foo.bar",
          },
          content: [],
        },
        {
          id: storyBlockID,
          userID: "abc",
          type: BlockType.Story,
          properties: {
            title: "foo",
          },
          content: [photoBlockID],
        },
      ],
    });
    expect(blocks).toHaveLength(2);
    expect(blocks[0].id).toEqual(photoBlockID);
    expect(blocks[1].id).toEqual(storyBlockID);
    expect(blocks[1].content).toHaveLength(1);
    expect(blocks[1].content).toContain(photoBlockID);
  }

  // Fetch the story.
  {
    const story = await getStoryWithID(storyBlockID);
    expect(story.id).toEqual(storyBlockID);
    expect(story.type).toEqual(BlockType.Story);
    expect(story.properties.title).toEqual("foo");
    expect(story.content).toHaveLength(1);
    expect(story.content[0].id).toEqual(photoBlockID);
  }

  // Replace the photo with some text.
  {
    const blocks = await editBlocks({
      insert: [
        {
          id: textBlockID,
          userID: "abc",
          type: BlockType.Text,
          properties: {
            title: "baz",
          },
          content: [],
        },
      ],
      update: [
        {
          id: storyBlockID,
          content: [textBlockID],
        },
      ],
      delete: [
        {
          id: photoBlockID,
        },
      ],
    });
    expect(blocks).toHaveLength(2);
    expect(blocks[0].id).toEqual(textBlockID);
    expect(blocks[1].id).toEqual(storyBlockID);
    expect(blocks[1].content).toHaveLength(1);
    expect(blocks[1].content).toContain(textBlockID);
  }

  // Refetch the story.
  {
    const story = await getStoryWithID(storyBlockID);
    expect(story.id).toEqual(storyBlockID);
    expect(story.type).toEqual(BlockType.Story);
    expect(story.properties.title).toEqual("foo");
    expect(story.content).toHaveLength(1);
    expect(story.content[0].id).toEqual(textBlockID);
  }
});
