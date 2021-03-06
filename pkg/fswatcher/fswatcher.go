package fswatcher

import (
	"context"
	"strings"
	"time"

	"github.com/fsnotify/fsnotify"
	"github.com/pkg/errors"
)

func Watch(ctx context.Context, dir string, eventCh chan<- struct{}) error {
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		return errors.Wrap(err, "failed to create watcher")
	}
	defer watcher.Close()

	err = watcher.Add(dir)
	if err != nil {
		return errors.Wrap(err, "watcher error")
	}

	for {
		select {
		// watch for events
		case event := <-watcher.Events:
			if event.Op&fsnotify.Create == fsnotify.Create ||
				event.Op&fsnotify.Write == fsnotify.Write {
				if strings.Contains(event.Name, dir) {
					// give time for other updates to occur
					time.Sleep(time.Second * 1)
					eventCh <- struct{}{}
				}
			}
		case err = <-watcher.Errors:
			return errors.Wrap(err, "watcher listen error")
		case <-ctx.Done():
			return nil
		}
	}
}
