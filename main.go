// main.go
package main

import (
  "flag"
  "net/http"
  "github.com/gorilla/mux"
  "github.com/golang/glog"
  "github.com/Lunkov/lib-mc"
  "github.com/Lunkov/lib-mc-rf/wasteout"
)

var service_port = ":3000"
var staticFS http.Handler

func SetupRoutes(router *mux.Router) {
  router.HandleFunc("/api/v1/status", WebStatus)
}

func WebStatus(w http.ResponseWriter, r *http.Request) {
  w.Header().Set("Access-Control-Allow-Origin", r.Header.Get("Origin"))
  w.Header().Set("Access-Control-Allow-Credentials", "true")
	w.Header().Set("Access-Control-Allow-Methods", "GET")
  w.Write([]byte(mc.GetPublicJson()))
}


func main() {
	flag.Set("alsologtostderr", "true")
	flag.Set("log_dir", ".")
  
  flag.Parse()
  
  mc.WorkerRegister(wasteout.NewWorker())
  
  go mc.Init("./etc/")
  defer mc.Close()
  
  router := mux.NewRouter()
  SetupRoutes(router)

  glog.Infof("LOG: Starting HTTP server on %s\n", service_port)
  http.ListenAndServe(service_port, router)
}
