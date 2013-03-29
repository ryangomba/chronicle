import { GetServerSidePropsContext, GetServerSidePropsResult } from "next";
import Link from "next/link";
import { BlockView } from "../../components/BlockView";
import { User, StoryBlock } from "../../models";
import styles from "../../styles/Story.module.css";

type Props = {
  user: User;
  story: StoryBlock;
};

export default function StoryPage(props: Props) {
  const { user, story } = props;
  const { properties, content } = story;
  const { title } = properties;
  return (
    <div className={styles.container}>
      <Link href={`/${user.username}`}>
        <h4>{user.displayName}</h4>
      </Link>
      <h1>{title}</h1>
      {content.map((block) => (
        <BlockView key={block.id} className={styles.block} block={block} />
      ))}
    </div>
  );
}

export const getServerSideProps = async (
  context: GetServerSidePropsContext
): Promise<GetServerSidePropsResult<Props>> => {
  const { username, storyID } = context.params;

  const userResponse = await fetch(`${process.env.API_ROOT}/users/${username}`);
  if (!userResponse.ok) {
    return {
      notFound: true,
    };
  }
  const { user } = await userResponse.json();

  const blockResponse = await fetch(
    `${process.env.API_ROOT}/users/${user.id}/blocks/${storyID}`
  );
  if (!blockResponse.ok) {
    return {
      notFound: true,
    };
  }
  const { block } = await blockResponse.json();

  return {
    props: {
      user,
      story: block,
    },
  };
};
