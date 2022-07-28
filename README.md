# Spring Dependencies with (limited) CVE Backports

This repository patches old versions of Spring with a few specific
backports to cover CVE-2022-22965[^2] ("SpringShell") and
CVE-2022-22950[^3].

It compiles a set of patched files derived from a fork of the
upstream Spring Framework repository[^1]. These live in the
`spring/` directory of each version.

It then overlays those files on top of their equivalent servicemix
bundle, to create a new servicemix bundle with an altered version.
The exception is Spring 3.1, which did not have a servicemix bundle;
in that case it simply creates a new version of the
org.springframework:spring-* jar.

It avoids using the `maven-bundle-plugin` to make sure the contents
are as close to the original jars as possible, instead relying
simply on unpacking dependencies with the `maven-dependency-plugin`,
and then re-packing them up with the `maven-assembly-plugin` and
forcing it to re-use the existing manifest.

[^1]: https://github.com/opennms-forge/spring-framework
[^2]: https://cve.mitre.org/cgi-bin/cvename.cgi?name=2022-22965
[^3]: https://cve.mitre.org/cgi-bin/cvename.cgi?name=2022-22950
