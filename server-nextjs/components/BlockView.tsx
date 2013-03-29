import { BlockType, SomeBlock } from "../models";
import { PhotoBlockView } from "./PhotoBlockView";
import { TextBlockView } from "./TextBlockView";

type Props = {
  className?: string;
  block: SomeBlock;
};

export function BlockView(props: Props) {
  switch (props.block.type) {
    case BlockType.Text:
      return <TextBlockView {...props} block={props.block} />;
    case BlockType.Photo:
      return <PhotoBlockView {...props} block={props.block} />;
    default:
      return null;
  }
}
