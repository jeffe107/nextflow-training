#!/usr/bin/env nextflow

/*
* Use echo to print 'Hello World!' to a file
*/

process hello_world {
    output:
        path 'hello.txt'
    script:
        '''
        echo "Hello world!" > hello.txt
        '''
}

process copy_file {
    input:
        path hello
    output:
        path 'copied_file.txt'
    script:
        """
        cp ${hello} copied_file.txt
        """
}

workflow {
    hello_world()
    copy_file(hello_world.out)
    
    publish:
    hello_folder = hello_world.out
    copy_folder = copy_file.out
}

output {
    hello_folder {
        path 'hello_folder'
    }
    copy_folder {
        path 'copy_folder'
    }
}