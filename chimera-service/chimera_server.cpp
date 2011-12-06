#include "Chimera.h"
#include <errno.h>
#include <fcntl.h>
#include <iostream>
#include <iterator>
#include <protocol/TBinaryProtocol.h>
#include <server/TSimpleServer.h>
#include <sstream>
#include <sys/file.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <syslog.h>
#include <transport/TBufferTransports.h>
#include <transport/TServerSocket.h>
#include <unistd.h>
#include <unordered_map>

using namespace ::apache::thrift;
using namespace ::apache::thrift::protocol;
using namespace ::apache::thrift::transport;
using namespace ::apache::thrift::server;
using namespace std;

typedef struct {
  string id;
  DeployStatus::type status;
  string manifest;
  PullStatus pullStatus;
} DeployInfo;

class ChimeraHandler : virtual public ChimeraIf {
 private:
  unordered_map<string, DeployInfo> activeDeployments;
  
 public:
  ChimeraHandler() {
    // Your initialization goes here
  }

  void ping(std::string& _return) {
    printf("ping\n");
    _return = "healthy";
  }

  void setDeploymentStart(const string deploymentId, const string manifest) {
    DeployInfo info;
    info.id = deploymentId;
    info.status = DeployStatus::PENDINGSTART;
    info.manifest = manifest;
    PullStatus pullStatus;
    info.pullStatus = pullStatus;
    activeDeployments.insert(make_pair(deploymentId, info));
  }

  void startDeployment(const std::string& deploymentId, const std::string& manifest) {
    ostringstream log;
    log << "starting deployment \"" << deploymentId << "\"" << endl;
    cout << log.str();
    setDeploymentStart(deploymentId, manifest);
    InternalError err;
    err.what = "Not implemented";
    err.where = "Chimera::startDeployment";
    cout << "not reallying starting the deployment" << endl;
  }

  void reportPullStatus(const string& deploymentId, const PullStatus& status) {
    auto depIter = activeDeployments.find(deploymentId);
    if (depIter == activeDeployments.end()) {
      return;
    }
    DeployInfo info = depIter->second;
    info.pullStatus = status;
    activeDeployments[deploymentId] = info;
  }

  DeployStatus::type getDeploymentStatus(const string& deploymentId) {
    auto depIter = activeDeployments.find(deploymentId);
    if (depIter == activeDeployments.end()) {
      cout << "Could not find deployment status for \"" << deploymentId << "\"" << endl;
      return DeployStatus::UNKNOWN;
    }
    cout << "Found deployment status" << endl;
    DeployInfo info = depIter->second;
    return info.status;
  }

  void getPullStatus(PullStatus& _return, const string& deploymentId) {
    auto depIter = activeDeployments.find(deploymentId);
    if (depIter == activeDeployments.end()) {
      cout << "Could not find pull status for \"" << deploymentId << "\"" << endl;
      PullStatus status;
      _return = status;
    }
    cout << "Found deployment status" << endl;
    DeployInfo info = depIter->second;
    _return = info.pullStatus;
  }
  
  void getDeployments(vector<string>& _return) {
    ostringstream log;
    log << "getting deployments" << endl;
    cout << log.str();
    vector<string> deployments;
    for (auto iter = activeDeployments.cbegin(); iter != activeDeployments.cend(); ++iter) {
      deployments.push_back(iter->first);
    }
    _return = deployments;
    cout << "returning " << deployments.size() << " deploymentIds"  << endl;
  }

  void reportStatus(const std::string& deploymentId, const DeployStatus::type status) {
    auto depIter = activeDeployments.find(deploymentId);
    if (depIter == activeDeployments.end()) {
      if (status == DeployStatus::STARTED) {
        setDeploymentStart(deploymentId, "");      
        depIter = activeDeployments.find(deploymentId);
      }
      else {
        return;
      }
    }
    DeployInfo info = depIter->second;
    DeployStatus::type oldStatus = info.status;
    info.status = status;
    activeDeployments[deploymentId] = info;
    cout << "updated status of deployment " << deploymentId << " from " << oldStatus << " to " << status << endl;
  }

  void deployTargets(const std::string& deploymentId, const std::vector<std::string>& targets, const std::string& environment) {
    printf("deployTargets\n");
    setDeploymentStart(deploymentId, "");
    pid_t pid = fork();
    if (pid < 0) {
      cout << "Major error! cannot fork!" << endl;
    }
    else if (pid == 0) {
      pid_t innerPid = fork();
      if (innerPid < 0 ) {
        cout << "Major error! cannot detach child by forking!" << endl;
      }
      else if (innerPid > 0) {
        _exit(0);
      }
      //We're the child of the child (properly detached from the parent)
      //time to exec the ruby script
      cout << "Hello from the detached child!" << endl;
      string manifestFile = "/tmp/manifest." + deploymentId;
      string path = "/chimera/bin/prep_and_deploy_package.rb";
      string name = "prep_and_deploy_package.rb";
      char** args = new char*[targets.size() + 4];
      args[targets.size() + 3] = 0;
      char* namec = new char[name.size() + 1];
      strcpy(namec, name.c_str());
      args[0] = namec;
      char* manifestc = new char[manifestFile.size() + 1];
      strcpy(manifestc, manifestFile.c_str());
      args[1] = manifestc;
      char* envc = new char[environment.size() + 1];
      strcpy(envc, environment.c_str());
      args[2] = envc;
      
      for (int i = 0; i < targets.size(); ++i) {
        char* arg = new char[targets[i].size() + 1];
        strcpy(arg, targets[i].c_str());
        args[i+3] = arg;
      }
      cout << "running execvp on " << path << endl;
      int ret = execvp(path.c_str(), args);
      int err = errno;
      cout << "FAILED TO EXEC! error value is " << err << ": " << strerror(err) << endl;
      _exit(ret);
    }
    else {
      //Wait for the child to die (after it forks another child)
      cout << "Waiting for detach" << endl;
      waitpid(pid, nullptr, 0);
      cout << "Detached." << endl;
    }
  }

};

static void child_handler(int signum)
{
    switch(signum) {
      case SIGALRM: syslog(LOG_INFO, "dying from SIGALARM"); exit(1); break;
      case SIGUSR1: exit(0); break;
      case SIGCHLD: syslog(LOG_INFO, "dying from SIGCHILD"); exit(1); break;
    }
}

static void daemonize( const char *lockfile )
{
    pid_t pid, sid, parent;
    int lfp = -1;

    /* already a daemon */
    if ( getppid() == 1 ) return;

    /* Create the lock file as the current user */
    if ( lockfile != nullptr && lockfile[0] ) {
        lfp = open(lockfile,O_RDWR|O_CREAT,0640);
        if ( lfp < 0 ) {
            syslog( LOG_ERR, "unable to create lock file %s, code=%d (%s)",
                    lockfile, errno, strerror(errno) );
            exit(1);
        }
        int lock = flock(lfp, LOCK_EX | LOCK_NB);
        if (lock && errno == EWOULDBLOCK) {
          syslog(LOG_ERR, "unable to lock on lock file %s, daemon is already running", lockfile);
          exit(1);
        }
    }

    /* Trap signals that we expect to recieve */
    signal(SIGCHLD,child_handler);
    signal(SIGUSR1,child_handler);
    signal(SIGALRM,child_handler);

    /* Fork off the parent process */
    pid = fork();
    if (pid < 0) {
        syslog( LOG_ERR, "unable to fork daemon, code=%d (%s)",
                errno, strerror(errno) );
        exit(1);
    }
    /* If we got a good PID, then we can exit the parent process. */
    if (pid > 0) {

        /* Wait for confirmation from the child via SIGTERM or SIGCHLD, or
           for three seconds to elapse (SIGALRM).  pause() should not return. */
        syslog(LOG_INFO, "daemon process started, pid=%d", pid);
        alarm(3);
        pause();

        exit(1);
    }

    /* At this point we are executing as the child process */
    parent = getppid();
    pid = getpid();
    ostringstream oss;
    oss << pid << endl;
    string pidstr = oss.str();
    write(lfp, pidstr.c_str(), pidstr.size());

    /* Cancel certain signals */
    signal(SIGCHLD,SIG_DFL); /* A child process dies */
    signal(SIGTSTP,SIG_IGN); /* Various TTY signals */
    signal(SIGTTOU,SIG_IGN);
    signal(SIGTTIN,SIG_IGN);
    signal(SIGHUP, SIG_IGN); /* Ignore hangup signal */
    signal(SIGTERM,SIG_DFL); /* Die on SIGTERM */

    /* Change the file mode mask */
    umask(0);

    /* Create a new SID for the child process */
    sid = setsid();
    if (sid < 0) {
        syslog( LOG_ERR, "unable to create a new session, code %d (%s)",
                errno, strerror(errno) );
        exit(1);
    }

    /* Change the current working directory.  This prevents the current
       directory from being locked; hence not being able to remove it. */
    if ((chdir("/")) < 0) {
        syslog( LOG_ERR, "unable to change directory to %s, code %d (%s)",
                "/", errno, strerror(errno) );
        exit(1);
    }

    /* Redirect standard files to /dev/null */
    freopen( "/dev/null", "r", stdin);
    freopen( "/dev/null", "w", stdout);
    freopen( "/dev/null", "w", stderr);

    /* Tell the parent process that we are A-okay */
    kill( parent, SIGUSR1 );
    syslog(LOG_INFO, "daemon running");
}

int main(int argc, char **argv) {
  vector<string> args;
  bool makeDaemon = true;
  for (int x = 0; x < argc; ++x) {
    args.push_back(argv[x]);
  }
  
  for (int x = 0; x < args.size(); ++x) {
    string arg = args[x];
    if (arg == "-h" || arg == "--help") {
      cout << "usage: chimera-server [options]" << endl;
      cout << "  -h    --help        This help dialog" << endl;
      cout << "  -n    --nodaemon    Prevents this process from becoming a daemon" << endl;
      cout << "                      (useful for debugging)" << endl;
      exit(0);
    }
    else if (arg == "-n" || arg == "--nodaemon") {
      makeDaemon = false;
    }
  }

  if (makeDaemon) {
    cout << "starting in daemon mode" << endl;
    openlog( "chimera", LOG_PID, LOG_LOCAL5 );
    syslog( LOG_INFO, "starting" );
    daemonize("/var/lock/chimera");  
  }
  else {
    cout << "not running as daemon" << endl;
  }

  int port = 6882;
  boost::shared_ptr<ChimeraHandler> handler(new ChimeraHandler());
  boost::shared_ptr<TProcessor> processor(new ChimeraProcessor(handler));
  boost::shared_ptr<TServerTransport> serverTransport(new TServerSocket(port));
  boost::shared_ptr<TTransportFactory> transportFactory(new TBufferedTransportFactory());
  boost::shared_ptr<TProtocolFactory> protocolFactory(new TBinaryProtocolFactory());

  TSimpleServer server(processor, serverTransport, transportFactory, protocolFactory);
  server.serve();
  return 0;
}
