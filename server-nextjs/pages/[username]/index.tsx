import { GetServerSidePropsContext, GetServerSidePropsResult } from "next";
import Link from "next/link";
import { User, StoryBlock } from "../../models";
import styles from "../../styles/User.module.css";

type Props = {
  user: User;
  stories: StoryBlock[];
};

export default function StoriesPage(props: Props) {
  const { user, stories } = props;
  return (
    <div>
      <h1>{user.displayName}</h1>
      {stories.map((story) => (
        <Link key={story.id} href={`/${user.username}/${story.id}`}>
          <p>{story.properties.title}</p>
        </Link>
      ))}
    </div>
  );
}

export const getServerSideProps = async (
  context: GetServerSidePropsContext
): Promise<GetServerSidePropsResult<Props>> => {
  const { username } = context.params;

  const userResponse = await fetch(`${process.env.API_ROOT}/users/${username}`);
  if (!userResponse.ok) {
    return {
      notFound: true,
    };
  }
  const { user } = await userResponse.json();

  const blocksResponse = await fetch(
    `${process.env.API_ROOT}/users/${user.id}/blocks?type=STORY`
  );
  if (!blocksResponse.ok) {
    return {
      notFound: true,
    };
  }
  const { blocks } = await blocksResponse.json();

  return {
    props: {
      user,
      stories: blocks,
    },
  };
};
