rm -rf \
	/root/.cache/go-build \
	/root/.cache/pip \
	/root/.local/share/NuGet/v3-cache/ \
	/root/.local/share/virtualenv/ \
	/root/.nuget/packages/ \
	/tmp/* \
	$GOPATH \
	/usr/local/share/.cache/yarn/ $@
