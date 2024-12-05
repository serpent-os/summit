/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.fixtures
 *
 * Basic JSON fixture mapping
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.fixtures;

import moss.service.context;
import std.path : buildPath;
import summit.models;
import summit.projects;
import vibe.core.file : readFileUTF8;
import vibe.d;
import vibe.data.json;

package:

struct FixtureRepo
{
    string name;
    string summary;
    string uri;
}

struct FixtureRemote
{
    string name;
    uint priority;
    string uri;
}

struct FixtureProfile
{
    string name;
    string arch;
    string indexURI;
    FixtureRemote[] remotes;
}

struct FixtureProject
{
    string name;
    string slug;
    string description;
    @optional FixtureProfile[] profiles;
    @optional FixtureRepo[] repos;
}

struct Fixture
{
    FixtureProject[] projects;
}

static void loadFixtures(ServiceContext context, ProjectManager projectManager) @safe
{
    immutable fixturePath = context.rootDirectory.buildPath("seed.json");
    auto fixture = fixturePath.readFileUTF8;
    auto fixtureRoot = parseJson(fixture);
    Fixture config = deserialize!(JsonSerializer, Fixture)(fixtureRoot);

    foreach (proj; config.projects)
    {
        auto project = projectManager.bySlug(proj.slug);
        /* Construct missing data for this project */
        if (project is null)
        {
            Project pj;
            pj.name = proj.name;
            pj.slug = proj.slug;
            pj.summary = proj.description;
            immutable err = projectManager.addProject(pj);
            enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
            project = projectManager.bySlug(proj.slug);
        }

        /* Ensure the repos are added */
        foreach (repo; proj.repos)
        {
            auto l = project.bySlug(repo.name);
            if (l !is null)
            {
                // Check if URI needs updating
                if (l.originURI != repo.uri)
                {
                    l.originURI = repo.uri;
                    immutable err = context.appDB.update((scope tx) => l.save(tx));
                    enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
                }
                continue;
            }
            Repository r;
            r.name = repo.name;
            r.summary = repo.summary;
            r.originURI = repo.uri;
            immutable err = project.addRepository(r);
            enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
        }

        /* Load the profiles */
        foreach (profile; proj.profiles)
        {
            auto l = project.profile(profile.name);
            if (l !is null)
            {
                // Check if URI needs updating
                if (l.volatileIndexURI != profile.indexURI)
                {
                    l.volatileIndexURI = profile.indexURI;
                    immutable err = context.appDB.update((scope tx) => l.save(tx));
                    enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
                }
                continue;
            }

            /* Construct it.. */
            Profile p;
            p.name = profile.name;
            p.arch = profile.arch;
            p.volatileIndexURI = profile.indexURI;
            immutable err = project.addProfile(p);
            enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
        }
    }
}
