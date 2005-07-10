<?php
#-
# Copyright (c) 2004-2005 FreeBSD GNOME Team <freebsd-gnome@FreeBSD.org>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# $MCom: portstools/tinderbox/webui/core/BuildPortsQueue.php,v 1.1 2005/07/10 07:39:18 oliver Exp $
#

    require_once 'TinderObject.php';

    class BuildPortsQueue extends TinderObject {

	function BuildPortsQueue($argv = array()) {
	    $object_hash = array(
                Build_Ports_Queue_Id => "",
		Build_Id => "",
		Build_Name => "",
		User_Id => "",
		User_Name => "",
		Port_Directory => "",
		Priority => "",
		Host_Id => "",
		Host_Name => ""
	    );

	    $this->TinderObject($object_hash, $argv);
	}

	function getId() {
	    return $this->Build_Ports_Queue_Id;
	}

	function getPortDirectory() {
	    return $this->Port_Directory;
	}

	function getPriority() {
	    return $this->Priority;
	}

	function getBuildId() {
	    return $this->Build_Id;
	}

	function getBuildName() {
	    return $this->Build_Name;
	}

	function getHostId() {
	    return $this->Host_Id;
	}

	function getHostName() {
	    return $this->Host_Name;
	}

	function getUserId() {
	    return $this->User_Id;
	}

	function getUserName() {
	    return $this->User_Name;
	}

	function getBuildPortsQueueId() {
	    return $this->Build_Ports_Queue_Id;
	}

    }
?>