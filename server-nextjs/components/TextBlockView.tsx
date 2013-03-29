import { TextBlock } from "../models";

type Props = {
  className?: string;
  block: TextBlock;
};

export function TextBlockView(props: Props) {
  const { title } = props.block.properties;
  return <p className={props.className}>{title}</p>;
}
