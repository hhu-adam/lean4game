import { spawn } from 'child_process'
import fs, { stat } from 'fs';
import request from 'request'
import requestProgress from 'request-progress'
import { Octokit } from 'octokit';

import { fileURLToPath } from 'url';
import path, { resolve } from 'path';
import { error } from 'console';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const TOKEN = process.env.LEAN4GAME_GITHUB_TOKEN
const USERNAME = process.env.LEAN4GAME_GITHUB_USER
const RESERVED_MEMORY = process.env.RESERVED_DISC_SPACE_MB
const CONTACT = process.env.ISSUE_CONTACT
const octokit = new Octokit({
  auth: TOKEN
})

const progress = {}
var exceedingMemoryLimit = false

async function runProcess(id, cmd, args, cwd) {
  return new Promise((resolve, reject) => {
    const ls = spawn(cmd, args, {cwd});

    ls.stdout.on('data', (data) => {
      progress[id].output += data.toString()
    });

    ls.stderr.on('data', (data) => {
      progress[id].output += data.toString()
    });

    ls.on('close', (code) => {
      resolve()
    });
  })
}


async function checkAgainstDiscMemory(artifact, reservedMemorySize) {
  return new Promise((resolve, reject) => {
  fs.statfs("/", (err, stats) => {
    if (err) {
      console.log(err);
      reject()
    }
    let artifactBytes = artifact.size_in_bytes;
    let totalBytes = stats.blocks * stats.bsize;
    let freeBytes = stats.bfree * stats.bsize;
    let usedBytes = totalBytes - freeBytes;
    const resMemoryBytes = reservedMemorySize * 1024 * 1024;
    if (usedBytes + artifactBytes >= resMemoryBytes) {
      exceedingMemoryLimit = true;
    }
    resolve()
  });
  })
}


async function download(id, url, dest) {
  return new Promise((resolve, reject) => {
    // The options argument is optional so you can omit it
    requestProgress(request({
      url,
      headers: {
        'accept': 'application/vnd.github+json',
        'User-Agent': USERNAME,
        'X-GitHub-Api-Version': '2022-11-28',
        'Authorization': 'Bearer ' + TOKEN
      }
    }))
    // choose latest artifact
    .on('progress', function (state) {
      console.log('progress', state);
      transferredDataSize = Math.round(state.size.transferred/1024/1024)
      progress[id].output += `Downloaded ${transferredDataSize}MB\n`
    })
    .on('error', function (err) {
      reject(err)
    })
    .on('end', function () {
      resolve()
    })
    .pipe(fs.createWriteStream(dest));
  })
}

async function doImport (owner, repo, id) {
  progress[id].output += `Import starting in a few seconds...\n`
  await new Promise(resolve => setTimeout(resolve, 3000))
  let artifactId = null
  try {
    const artifacts = await octokit.request('GET /repos/{owner}/{repo}/actions/artifacts', {
      owner,
      repo,
      headers: {
        'X-GitHub-Api-Version': '2022-11-28'
      }
    })
    const artifact = artifacts.data.artifacts
      .reduce((acc, cur) => acc.created_at < cur.created_at ? cur : acc)

    await checkAgainstDiscMemory(artifact, RESERVED_MEMORY);

    if (exceedingMemoryLimit === true) {
      const artifact_size_mb = Math.round(artifact.size_in_bytes / 1024 / 1024);
      console.error(`[${new Date()}] ABORT IMPORT: Uploading file of size ${artifact_size_mb} (MB) by ${owner} would exceed allocated memory on the server.`)
      throw new Error(`Uploading file of size ${artifact_size_mb} (MB) would exceed allocated memory on the server.\n
      Please notify server admins via <a href=${CONTACT}>the LEAN zulip instance</a> to resolve this issue.`);
    }

    artifactId = artifact.id
    const url = artifact.archive_download_url
    // Make sure the download folder exists
    if (!fs.existsSync(path.join(__dirname, "..", "games"))){
      fs.mkdirSync(path.join(__dirname, "..", "games"));
    }
    if (!fs.existsSync(path.join(__dirname, "..", "games", "tmp"))){
      fs.mkdirSync(path.join(__dirname, "..", "games", "tmp"));
    }
    progress[id].output += `Download from ${url}\n`
    await download(id, url, path.join(__dirname, "..", "games", "tmp", `${owner.toLowerCase()}_${repo.toLowerCase()}_${artifactId}.zip`))
    progress[id].output += `Download finished.\n`

    await runProcess(id, "/bin/bash", [path.join(__dirname, "unpack.sh"), artifactId, owner.toLowerCase(), repo.toLowerCase()], path.join(__dirname, ".."))

    // let manifest = fs.readFileSync(`tmp/artifact_${artifactId}_inner/manifest.json`);
    // manifest = JSON.parse(manifest);
    // if (manifest.length !== 1) {
    //   throw `Unexpected manifest: ${JSON.stringify(manifest)}`
    // }
    // manifest[0].RepoTags = [`g/${owner.toLowerCase()}/${repo.toLowerCase()}:latest`]
    // fs.writeFileSync(`tmp/artifact_${artifactId}_inner/manifest.json`, JSON.stringify(manifest));
    // await runProcess(id, "tar", ["-cvf", `../archive_${artifactId}.tar`, "."], `tmp/artifact_${artifactId}_inner/`)
    // // await runProcess(id, "docker", ["load", "-i", `tmp/archive_${artifactId}.tar`])

    progress[id].done = true
    progress[id].output += `Done!\n`
    progress[id].output += `Play the game at: {your website}/#/g/${owner}/${repo}\n`
  } catch (e) {
    progress[id].output += `Error: ${e.toString()}\n${e.stack}`
  } finally {
    // clean-up temp. files
    if (artifactId) {
      fs.rmSync(path.join(__dirname, "..", "games", "tmp", `${owner}_${repo}_${artifactId}.zip`), {force: true, recursive: false});
      fs.rmSync(path.join(__dirname, "..", "games", "tmp", `${owner}_${repo}_${artifactId}`), {force: true, recursive: true});
    }
    progress[id].done = true
  }
  await new Promise(resolve => setTimeout(resolve, 10000))
}

export const importTrigger = (req, res) => {
  const owner = req.params.owner
  const repo = req.params.repo
  const id = req.params.owner + '/' + req.params.repo
  if(!/^[\w.-]+\/[\w.-]+$/.test(id)) { res.send(`Invalid repo name ${id}`); return }

  if(!progress[id] || progress[id].done) {
    progress[id] = {output: "", done: false}
    doImport(owner, repo, id)
  }

  res.redirect(`/import/status/${owner}/${repo}`)
}

export const importStatus = (req, res) => {
  const owner = req.params.owner
  const repo = req.params.repo
  const id = req.params.owner + '/' + req.params.repo
  res.send(`<html><head><meta http-equiv="refresh" content="5"></head><body><pre>${progress[id]?.output ?? "Nothing here."}</pre></body></html>`)
}
