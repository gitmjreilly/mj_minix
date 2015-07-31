Mount a minix v1 file system onto Linux as follows
	mount -o loop -t minix FileWFileSystem /mntpoint

Dump File, byte oriented, hex format
	od -t x1 -Ax filename

Creating a Minix v1 filesystem
	mkfs.minix -n 14 -i inodecount device SizeInBlocks

	Device must an existing file large enough to hold file system
	Num inodes will be rounded up to fill a block

Using fsck.minix
	fsck -vf filename
