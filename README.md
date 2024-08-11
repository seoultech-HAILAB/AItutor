# AItutor

## Hosting
- [https://ai-tutor-27e63.web.app/](https://ai-tutor-27e63.web.app/)

1. flutter build web 
2. firebase deploy --only hosting

## Version
```bash
$ flutter --version
```
* Flutter 3.22.3 • channel [user-branch] • unknown source
* Tools • Dart 3.4.4 • DevTools 2.34.3

## Firebase Hosting
1. firebase init
2. select option: Hosting
3. use an existing project
4. public directory: build/web
5. configure as a single-page app: n
6. github: n
7. flutter build web
8. firebase deploy --only hosting