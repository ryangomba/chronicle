import { PhotoBlock } from "../models";

type Props = {
  className?: string;
  block: PhotoBlock;
};

export function PhotoBlockView(props: Props) {
  const { source } = props.block.properties;
  return (
    <img className={props.className} style={{ width: "100%" }} src={source} />
  );
}
