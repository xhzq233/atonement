importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyC2mNHKdvZQIKNGXBeJPQV6riXnV9RGhQU",
  authDomain: "xhzq233-firebase-demo.firebaseapp.com",
  projectId: "xhzq233-firebase-demo",
  storageBucket: "xhzq233-firebase-demo.appspot.com",
  messagingSenderId: "80750108764",
  appId: "1:80750108764:web:93bbb279b8bff342430699",
  measurementId: "G-ZNR9T05ENR"
});
// Necessary to receive background messages:
const messaging = firebase.messaging();

//// Optional:
//messaging.onBackgroundMessage((m) => {
//  console.log("onBackgroundMessage", m);
//
//  // Customize notification here
//    const notificationTitle = 'Background Message Title';
//    const notificationOptions = {
//      body: 'Background Message body.',
//      icon: '/firebase-logo.png'
//    };
//
//    self.registration.showNotification(notificationTitle,
//      notificationOptions);
//});