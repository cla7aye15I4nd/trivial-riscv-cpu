import os
import shutil

for f in os.listdir('package'):
    name = f[:-2]
    if f[-2:] == ".c":
        yn = input(f"Do you need test {name}.c?(y/n)")
        if yn.lower() != 'n':
            print(f"Start test {name}..")
            shutil.copy('tb.o', os.path.join('tmp','tb.o'))
            shutil.copy(os.path.join('package', f'{name}.data'),
                        os.path.join('tmp', 'test.data'))
            shutil.copy(os.path.join('package', f'{name}.ans'),
                        os.path.join('tmp', 'test.ans'))
            os.chdir('tmp')
            os.system('vvp tb.o > tb.out')
            with open('tb.out') as f:
                text = f.read()
            with open('test.ans') as f:
                ans = f.read()
            out = '\n'.join(text[:-10].split('\n')[1:])
            if ans == out:
                print("Accepted")
            else:
                print("Wrong")
            os.chdir('..')
        print()
