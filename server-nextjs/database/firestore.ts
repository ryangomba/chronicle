import firebase from "firebase";

let app = firebase.apps[0];
if (!app) {
  app = firebase.initializeApp({
    projectId: "chronicle-298101",
    appId: "",
    apiKey: "",
    authDomain: "",
    storageBucket: "",
    messagingSenderId: "",
    measurementId: "",
  });
}

export const DB = firebase.firestore(app);
