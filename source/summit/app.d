/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.app
 *
 * Core application lifecycle
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module summit.app;

import moss.core.errors;
import moss.service.accounts;
import moss.service.context;
import moss.service.models;
import std.path : buildPath;
import summit.api;
import summit.build;
import summit.models;
import summit.projects;
import summit.web;
import vibe.core.file : readFileUTF8;
import vibe.d;
import vibe.data.json;

/**
 * SummitApplication provides the main dashboard application
 * seen by users after the setup app is complete.
 */
public final class SummitApplication
{
    @disable this();

    /**
     * Construct new App 
     *
     * Params:
     *      context = application context
     */
    this(ServiceContext context) @safe
    {
        this.context = context;
        this.projectManager = new ProjectManager(context);
        this.buildManager = new BuildManager(context, projectManager);
        immutable err = projectManager.connect();
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
        _router = new URLRouter();
        web = new SummitWeb(context, projectManager, router);
        service = new RESTService(context, projectManager, router);

        loadFixtures();
    }

    /**
     * Returns: mapped router
     */
    pragma(inline, true) pure @property URLRouter router() @safe @nogc nothrow
    {
        return _router;
    }

    /**
     * Close down the app/instance
     */
    void close() @safe
    {
        projectManager.close();
    }

private:

    static struct FixtureRepo
    {
        string name;
        string summary;
        string uri;
    }

    static struct FixtureRemote
    {
        string name;
        uint priority;
        string uri;
    }

    static struct FixtureProfile
    {
        string name;
        string arch;
        string indexURI;
        FixtureRemote[] remotes;
    }

    static struct FixtureProject
    {
        string name;
        string slug;
        string description;
        @optional FixtureProfile[] profiles;
        @optional FixtureRepo[] repos;
    }

    static struct Fixture
    {
        FixtureProject[] projects;
    }

    void loadFixtures() @safe
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

    ProjectManager projectManager;
    BuildManager buildManager;
    ServiceContext context;
    RESTService service;
    URLRouter _router;
    SummitWeb web;
}
