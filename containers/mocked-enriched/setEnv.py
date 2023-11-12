import os

def getEnvDataAsDict(path: str) -> dict:
    with open(path, 'r') as f:
       return dict(tuple(line.replace('\n', '').split('=')) for line
                in f.readlines() if not line.startswith('#'))

def loadEnvVar():
    try:
        print("setEnv - Loading variables.")
        ## Fetch the env variables and ensure they are set in the os.environ
        envVariables = getEnvDataAsDict('.env')
        for variable in envVariables.keys():
            print("Adding "+variable)
            os.environ[variable] = envVariables[variable]
            try:
                if os.environ[variable]:
                    pass
                else:
                    return False
            except Exception as e:
                print(e)
                return False
        return True
    except Exception as e:
        print(e)
        return False
