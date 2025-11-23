const path = require("path");
const semver = require("semver");
const child_process = require("child_process");
// const { Remote } = require("nodegit");
// const { stdout } = require("process");

const REPOURL = process.argv.slice(2); // "https://go.googlesource.com/go";

/*
b95f84a867c5ff09b781140ff021bd36572e3edc	refs/users/90/5190/edit-40810/1
90f54af49d84f9c09d056e41aed85d6f84048008	refs/users/95/5195/edit-35108/1
git ls-remote "https://go.googlesource.com/go"
*/
// const Git = require("nodegit");
class Remote {
  constructor(strout) {
    this.remotes = strout
      .split(/[\n\r]+/)
      .map((line) => line.split(/\s+/))
      .filter((arr) => arr.length == 2)
      .map(([ref, name]) => ({ ref: () => ref, name: () => name }));
    // console.log(strout);
    // console.log(this.remotes[0].name());
    // console.log(this.remotes[0].ref());
  }
  connect(_) {
    return Promise.resolve(this.remotes.length);
  }
  referenceList() {
    return Promise.resolve(this.remotes);
  }
}
const Git = {
  Remote: {
    createDetached: (url) => {
      return new Promise((rs, rj) => {
        child_process.exec(
          `git ls-remote ${url}`,
          { maxBuffer: 64 * 1024 * 1024 },
          (err, strout, strerr) => {
            if (err) {
              console.error(strerr);
              rj(err);
              return;
            }
            rs(new Remote(strout));
          }
        );
      });
    },
  },
  Enums: {
    DIRECTION: {
      FETCH: "fetch",
    },
  },
};
function getTags(repoUrl, cbTags) {
  Git.Remote.createDetached(repoUrl).then((remote) => {
    remote.connect(Git.Enums.DIRECTION.FETCH).then((number) => {
      remote.referenceList().then((array) => {
        // console.log(array.map(i => i.name()))
        cbTags(
          array
            .map((i) => i.name())
            .filter((i) => i.startsWith("refs/tags/"))
            .map((i) => path.basename(i))
        );
      });
    });
  });
}

process.argv.slice(2).forEach((repoUrl) =>
  getTags(repoUrl, (tags) => {
    const tag_prefix = path.basename(repoUrl);
    const nullVersion = new semver.SemVer("0.0.0");
    const maxver = tags
      .filter((i) => i.startsWith(tag_prefix))
      .map((i) => i.slice(tag_prefix.length))
      .map((i) => {
        let fixedVersion = i;
        if (i.match(/^\d+$/)) {
          fixedVersion = `${i}.0.0`;
        }
        if (i.match(/^\d+\.\d+$/)) {
          fixedVersion = `${i}.0`;
        }
        let semVersion;
        try {
          semVersion = new semver.SemVer(fixedVersion);
        } catch (e) {}
        return {
          orig: i,
          semver: semVersion,
        };
      })
      .filter((i) => i.semver && i.semver.prerelease.length === 0)
      .reduce((r, i) => (i.semver.compare(r.semver) > 0 ? i : r), {
        orig: "nothing.found",
        semver: nullVersion,
      });
    console.log(
      `${tag_prefix.toUpperCase().replace(/[^A-Z0-9]/g, "_")}_VERSION=${
        maxver.orig
      }`
    );
  })
);
